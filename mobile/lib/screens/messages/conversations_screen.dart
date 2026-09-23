import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../services/socket_service.dart';
import '../../widgets/common.dart';
import 'chat_screen.dart';
import 'applications_screen.dart';

/// تبويبان: المحادثات وطلبات التوظيف (3.7)
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<ConversationModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    SocketService.instance.onMessage.addListener(_load);
  }

  @override
  void dispose() {
    SocketService.instance.onMessage.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final items = await MessageService.conversations();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الرسائل'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: [
              Tab(text: 'المحادثات'),
              Tab(text: 'طلبات التوظيف'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _conversationsTab(),
            // الباحث يرى طلباته؛ المؤسسة ترى الترشّحات المستلمة
            ApplicationsScreen(isCompany: auth.isCompany),
          ],
        ),
      ),
    );
  }

  Widget _conversationsTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return EmptyState(
        icon: PhosphorIcons.chatsCircle(PhosphorIconsStyle.regular),
        title: 'لا توجد محادثات',
        subtitle: 'تبدأ المحادثة بعد تقديم طلب توظيف أو استلامه',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
        itemBuilder: (_, i) {
          final c = _items[i];
          final unread = c.unreadCount > 0;

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: c.otherParty?.avatarUrl != null
                  ? NetworkImage(c.otherParty!.avatarUrl!)
                  : null,
              child: c.otherParty?.avatarUrl == null
                  ? Icon(
                      c.otherParty?.isCompany ?? false
                          ? PhosphorIcons.buildings(PhosphorIconsStyle.fill)
                          : PhosphorIcons.user(PhosphorIconsStyle.fill),
                      color: AppColors.primary,
                      size: 22,
                    )
                  : null,
            ),
            title: Text(
              c.otherParty?.fullName ?? 'محادثة',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.offerTitle != null)
                  Text(
                    c.offerTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.primary),
                  ),
                Text(
                  c.lastMessage ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: unread
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeAgo(c.lastMessageAt),
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                if (unread)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${c.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: c.id,
                  title: c.otherParty?.fullName ?? 'محادثة',
                  otherUserId: c.otherParty?.id,
                ),
              ),
            ).then((_) => _load()),
          );
        },
      ),
    );
  }
}
