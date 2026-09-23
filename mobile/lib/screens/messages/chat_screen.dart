import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../services/socket_service.dart';
import '../../widgets/common.dart';

/// محادثة مباشرة بين المؤسسة والمترشّح (3.7)
class ChatScreen extends StatefulWidget {
  final String? conversationId;
  final String? applicationId;
  final String title;
  final String? otherUserId;

  const ChatScreen({
    super.key,
    this.conversationId,
    this.applicationId,
    required this.title,
    this.otherUserId,
  }) : assert(conversationId != null || applicationId != null,
            'يجب تمرير معرّف المحادثة أو الترشّح');

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<MessageModel> _messages = [];

  /// معرّفات الرسائل المعروضة — تمنع التكرار بين ردّ الإرسال والمقبس
  final Set<String> _seenIds = {};

  StreamSubscription<SocketMessage>? _msgSub;
  StreamSubscription<TypingEvent>? _typingSub;
  Timer? _typingTimer;
  Timer? _typingThrottle;

  String? _conversationId;
  String? _otherUserId;
  bool _loading = true;
  bool _sending = false;
  bool _otherTyping = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _otherUserId = widget.otherUserId;

    if (_conversationId != null) {
      _load();
    } else {
      // محادثة جديدة تُنشأ عند إرسال أوّل رسالة
      _loading = false;
    }

    _msgSub = SocketService.instance.messages.listen(_onSocketMessage);
    _typingSub = SocketService.instance.typing.listen(_onTyping);
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _typingSub?.cancel();
    _typingTimer?.cancel();
    _typingThrottle?.cancel();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSocketMessage(SocketMessage event) {
    if (!mounted) return;
    if (event.conversationId != _conversationId) return;

    final msg = MessageModel.fromJson(event.message);
    if (_seenIds.contains(msg.id)) return; // وصلت مسبقًا

    setState(() {
      _seenIds.add(msg.id);
      _messages.add(msg);
      _otherTyping = false;
    });
    _scrollToBottom();
  }

  void _onTyping(TypingEvent event) {
    if (!mounted) return;
    if (event.conversationId != _conversationId) return;

    setState(() => _otherTyping = true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _otherTyping = false);
    });
  }

  Future<void> _load() async {
    try {
      final (conversation, messages) =
          await MessageService.messages(_conversationId!);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
        _seenIds
          ..clear()
          ..addAll(messages.map((m) => m.id));
        _otherUserId ??= conversation.otherParty?.id;
        _loading = false;
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: AppMotion.normal,
          curve: AppMotion.curve,
        );
      }
    });
  }

  /// يُرسل حدث «يكتب» مرّة كل ثانيتين كحدّ أقصى
  void _notifyTyping() {
    if (_conversationId == null || _otherUserId == null) return;
    if (_typingThrottle?.isActive ?? false) return;

    SocketService.instance.emitTyping(_conversationId!, _otherUserId!);
    _typingThrottle = Timer(const Duration(seconds: 2), () {});
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final (message, convId) = await MessageService.send(
        conversationId: _conversationId,
        applicationId: _conversationId == null ? widget.applicationId : null,
        body: text,
      );
      if (!mounted) return;
      setState(() {
        _conversationId = convId;
        if (!_seenIds.contains(message.id)) {
          _seenIds.add(message.id);
          _messages.add(message);
        }
        _ctrl.clear();
      });
      _scrollToBottom();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        title: Column(
          children: [
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            // مؤشّر «يكتب» أو حالة الاتصال أسفل الاسم
            ValueListenableBuilder<bool>(
              valueListenable: SocketService.instance.connected,
              builder: (_, online, __) {
                final label = _otherTyping
                    ? 'يكتب الآن...'
                    : (online ? 'متّصل' : 'جارٍ إعادة الاتصال...');
                return Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _otherTyping
                        ? AppColors.goldLight
                        : (online ? Colors.white70 : Colors.white54),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Loader()
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : _messages.isEmpty
                        ? const EmptyState(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'ابدأ المحادثة',
                            subtitle: 'اكتب رسالتك الأولى في الأسفل',
                          )
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            itemCount:
                                _messages.length + (_otherTyping ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i >= _messages.length) {
                                return const _TypingBubble();
                              }
                              final m = _messages[i];
                              return _bubble(m, m.senderId == myId);
                            },
                          ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _composer() => Container(
        padding: EdgeInsets.fromLTRB(
            12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: AppShadows.lifted,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLines: 4,
                minLines: 1,
                maxLength: 2000,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => _notifyTyping(),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  counterText: '',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            PressableScale(
              onTap: _sending ? null : _send,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppShadows.colored(AppColors.primary),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 21),
              ),
            ),
          ],
        ),
      );

  Widget _bubble(MessageModel m, bool isMine) => Align(
        alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            gradient: isMine ? AppColors.primaryGradient : null,
            color: isMine ? null : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 4 : 16),
              bottomRight: Radius.circular(isMine ? 16 : 4),
            ),
            border: isMine ? null : Border.all(color: AppColors.border),
            boxShadow: isMine ? null : AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                m.body,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: isMine ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    m.createdAt == null
                        ? ''
                        : '${m.createdAt!.hour.toString().padLeft(2, '0')}:'
                            '${m.createdAt!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isMine ? Colors.white60 : AppColors.textMuted,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      m.readAt != null
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 12,
                      color: m.readAt != null
                          ? AppColors.goldLight
                          : Colors.white60,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
}

/// فقاعة «يكتب الآن» بثلاث نقاط متحرّكة
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                // كل نقطة تتأخّر عن سابقتها
                final t = (_c.value + i * 0.22) % 1.0;
                final scale = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      );
}
