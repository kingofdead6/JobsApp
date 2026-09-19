import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_services.dart';
import '../services/socket_service.dart';
import 'home/home_screen.dart';
import 'messages/conversations_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/account_screen.dart';
import 'more/more_screen.dart';

/// الهيكل الرئيسي مع شريط التنقّل السفلي الخماسي (كما في التصميم)
class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 2});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  int _unreadMessages = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _refreshBadges();

    // تحديث الشارات فور وصول رسالة أو إشعار
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
      // الشارات ليست حرجة — نتجاهل الخطأ بصمت
    }
  }

  @override
  Widget build(BuildContext context) {
    // ترتيب التبويبات من اليمين لليسار يطابق التصميم:
    // حسابي · الرسائل · الرئيسية · الإشعارات · المزيد
    final pages = [
      const AccountScreen(),
      const ConversationsScreen(),
      HomeScreen(onNavigateTab: (i) => setState(() => _index = i)),
      const NotificationsScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
          if (i == 1 || i == 3) _refreshBadges();
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'حسابي',
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
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
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
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }
}

/// شارة عدد غير المقروء فوق أيقونة التبويب
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
              color: const Color(0xFFDC2626),
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
