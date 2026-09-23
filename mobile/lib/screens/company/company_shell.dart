import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/company_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../services/socket_service.dart';
import '../messages/conversations_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/account_screen.dart';
import 'company_dashboard_screen.dart';
import 'my_jobs_screen.dart';

/// الهيكل الخاص بجانب المؤسسات — تبويبات مختلفة كليًا عن جانب الباحث:
/// لوحة · عروضي · الرسائل · الإشعارات · حسابي
class CompanyShell extends StatefulWidget {
  final int initialIndex;
  const CompanyShell({super.key, this.initialIndex = 0});

  @override
  State<CompanyShell> createState() => _CompanyShellState();
}

class _CompanyShellState extends State<CompanyShell> {
  late int _index = widget.initialIndex;

  int _unreadMessages = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _refreshBadges();
    SocketService.instance.onMessage.addListener(_refreshBadges);
    SocketService.instance.onNotification.addListener(_refreshBadges);
  }

  @override
  void dispose() {
    SocketService.instance.onMessage.removeListener(_refreshBadges);
    SocketService.instance.onNotification.removeListener(_refreshBadges);
    super.dispose();
  }

  Future<void> _refreshBadges() async {
    if (!mounted) return;
    if (!context.read<AuthProvider>().isAuthenticated) return;
    try {
      final messages = await MessageService.unreadCount();
      final (_, notifications) = await MiscService.notifications();
      if (!mounted) return;
      setState(() {
        _unreadMessages = messages;
        _unreadNotifications = notifications;
      });
    } catch (_) {
      // الشارات ليست حرجة
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CompanyDashboardScreen(
          onNavigateTab: (i) => setState(() => _index = i)),
      const MyJobsScreen(embedded: true),
      const ConversationsScreen(),
      const NotificationsScreen(),
      const AccountScreen(),
    ];

    // السمة الخاصّة بالمؤسسة تُطبَّق على كل الشاشات داخل هذا الهيكل
    return CompanyScope(
      child: Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: AppShadows.lifted,
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) {
              setState(() => _index = i);
              if (i == 2 || i == 3) _refreshBadges();
            },
            selectedItemColor: CompanyColors.primary,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'لوحة',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.work_outline_rounded),
                activeIcon: Icon(Icons.work_rounded),
                label: 'عروضي',
              ),
              BottomNavigationBarItem(
                icon: _Badge(
                  count: _unreadMessages,
                  child: const Icon(Icons.mail_outline_rounded),
                ),
                activeIcon: _Badge(
                  count: _unreadMessages,
                  child: const Icon(Icons.mail_rounded),
                ),
                label: 'الرسائل',
              ),
              BottomNavigationBarItem(
                icon: _Badge(
                  count: _unreadNotifications,
                  child: const Icon(Icons.notifications_outlined),
                ),
                activeIcon: _Badge(
                  count: _unreadNotifications,
                  child: const Icon(Icons.notifications_rounded),
                ),
                label: 'الإشعارات',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Widget child;

  const _Badge({required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 17),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
