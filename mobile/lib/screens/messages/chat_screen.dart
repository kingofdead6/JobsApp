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
  String? _conversationId;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    if (_conversationId != null) {
      _load();
    } else {
      // محادثة جديدة تُنشأ عند إرسال أول رسالة
      _loading = false;
    }
    SocketService.instance.onMessage.addListener(_onSocketMessage);
  }

  @override
  void dispose() {
    SocketService.instance.onMessage.removeListener(_onSocketMessage);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSocketMessage() {
    final data = SocketService.instance.onMessage.value;
    if (data == null) return;
    if (data['conversationId'] != _conversationId) return;

    final msg = data['message'];
    if (msg is! Map) return;

    setState(() {
      _messages.add(MessageModel.fromJson(Map<String, dynamic>.from(msg)));
    });
    _scrollToBottom();
  }

  Future<void> _load() async {
    try {
      final (_, messages) = await MessageService.messages(_conversationId!);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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
        _messages.add(message);
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
        ),title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
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
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                              final m = _messages[i];
                              final isMine = m.senderId == myId;
                              return _bubble(m, isMine);
                            },
                          ),
          ),

          // حقل الإرسال
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              10 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
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
                    onChanged: (_) {
                      if (_conversationId != null && widget.otherUserId != null) {
                        SocketService.instance
                            .emitTyping(_conversationId!, widget.otherUserId!);
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      counterText: '',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: _sending ? null : _send,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(MessageModel m, bool isMine) => Align(
        alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isMine ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 4 : 16),
              bottomRight: Radius.circular(isMine ? 16 : 4),
            ),
            border: isMine ? null : Border.all(color: AppColors.border),
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
            ],
          ),
        ),
      );
}
