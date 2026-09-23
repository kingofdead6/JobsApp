import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../services/api_services.dart';
import '../../services/socket_service.dart';
import '../../widgets/common.dart';
import '../jobs/job_detail_screen.dart';
import '../jobs/jobs_list_screen.dart';
import '../messages/chat_screen.dart';

/// الإشعارات (3.7)
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    SocketService.instance.onNotification.addListener(_load);
  }

  @override
  void dispose() {
    SocketService.instance.onNotification.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final (items, _) = await MiscService.notifications();
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

  Future<void> _markAllRead() async {
    try {
      await MiscService.markRead();
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _open(NotificationModel n) async {
    if (!n.isRead) {
      await MiscService.markRead(id: n.id);
      if (mounted) _load();
    }
    if (!mounted) return;

    final data = n.data ?? {};

    // التنقّل حسب نوع الإشعار
    switch (n.type) {
      case 'offer_approved':
      case 'offer_rejected':
      case 'new_application':
        final offerId = data['offerId'];
        if (offerId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => JobDetailScreen(offerId: '$offerId')),
          );
        }
        break;

      case 'application_status':
        final offerId = data['offerId'];
        if (offerId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => JobDetailScreen(offerId: '$offerId')),
          );
        }
        break;

      case 'new_message':
        final convId = data['conversationId'];
        if (convId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ChatScreen(conversationId: '$convId', title: 'محادثة'),
            ),
          );
        }
        break;

      case 'matching_offer':
        final criteria = data['criteria'] as Map?;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobsListScreen(
              initialQuery: criteria?['q'] as String?,
              initialWilaya: criteria?['wilaya'] as String?,
            ),
          ),
        );
        break;
    }
  }

  static (IconData, Color) _visual(String type) => switch (type) {
        'matching_offer' => (Icons.work_rounded, AppColors.tileGreen),
        'application_status' => (Icons.assignment_turned_in_rounded, AppColors.info),
        'new_message' => (Icons.chat_bubble_rounded, AppColors.tilePurple),
        'offer_approved' => (Icons.check_circle_rounded, AppColors.success),
        'offer_rejected' => (Icons.cancel_rounded, AppColors.danger),
        'new_application' => (Icons.person_add_rounded, AppColors.tileOrange),
        'company_verified' => (Icons.verified_rounded, AppColors.info),
        _ => (Icons.campaign_rounded, AppColors.primary),
      };

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.isRead);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),        title: const Text('الإشعارات'),
        automaticallyImplyLeading: false,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('تعليم الكل كمقروء',
                  style: TextStyle(color: Colors.white, fontSize: 12.5)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'لا توجد إشعارات',
                      subtitle: 'ستصلك هنا تنبيهات العروض والطلبات والرسائل',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (_, i) {
                          final n = _items[i];
                          final (icon, color) = _visual(n.type);

                          return Dismissible(
                            key: ValueKey(n.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: AppColors.danger,
                              alignment: AlignmentDirectional.centerStart,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete_rounded,
                                  color: Colors.white),
                            ),
                            onDismissed: (_) {
                              MiscService.deleteNotification(n.id);
                              setState(() => _items.removeAt(i));
                            },
                            child: Container(
                              color: n.isRead
                                  ? null
                                  : AppColors.primary.withValues(alpha: 0.03),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(icon, color: color, size: 21),
                                ),
                                title: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: n.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w800,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (n.body != null)
                                      Text(
                                        n.body!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                          height: 1.5,
                                        ),
                                      ),
                                    const SizedBox(height: 3),
                                    Text(
                                      timeAgo(n.createdAt),
                                      style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                trailing: n.isRead
                                    ? null
                                    : Container(
                                        width: 9,
                                        height: 9,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                onTap: () => _open(n),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
