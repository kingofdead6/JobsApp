import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../auth/welcome_screen.dart';
import '../company/company_profile_screen.dart';
import '../company/my_jobs_screen.dart';
import '../messages/applications_screen.dart';
import '../saved/saved_screen.dart';
import 'cv_screen.dart';
import 'edit_profile_screen.dart';

/// شاشة «حسابي» — القائمة الجانبية كما في التصميم
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
            flexibleSpace: const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            ),
            title: const Text('حسابي'),
            automaticallyImplyLeading: false),
        body: EmptyState(
          icon: Icons.person_outline_rounded,
          title: 'لم تسجّل الدخول بعد',
          subtitle: 'سجّل الدخول للوصول إلى حسابك',
          action: SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (_) => false,
              ),
              child: const Text('تسجيل الدخول'),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          title: const Text('حسابي'),
          automaticallyImplyLeading: false),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ترويسة المستخدم
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Icon(
                          user.isCompany
                              ? Icons.business_rounded
                              : Icons.person_rounded,
                          size: 32,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.isCompany
                            ? 'حساب مؤسسة'
                            : user.isAdmin
                                ? 'مشرف المنصّة'
                                : 'باحث عن عمل',
                        style: const TextStyle(
                            fontSize: 12.5, color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.phone,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // مداخل الباحث عن عمل
          if (auth.isSeeker) ...[
            _tile(
              context,
              icon: Icons.person_outline_rounded,
              label: 'الملف الشخصي',
              onTap: () {
                final profile = auth.profile;
                if (profile == null) {
                  showSnack(context, 'جارٍ تحميل الملف...', error: true);
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EditProfileScreen(profile: profile, user: user),
                  ),
                );
              },
            ),
            _tile(
              context,
              icon: Icons.description_outlined,
              label: 'سيرتي الذاتية',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CvScreen()),
              ),
            ),
            _tile(
              context,
              icon: Icons.assignment_outlined,
              label: 'طلبات التوظيف',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                        flexibleSpace: const DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient),
                        ),
                        title: const Text('طلبات التوظيف')),
                    body: const ApplicationsScreen(),
                  ),
                ),
              ),
            ),
            _tile(
              context,
              icon: Icons.bookmark_border_rounded,
              label: 'العروض المحفوظة',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedScreen()),
              ),
            ),
          ],

          // مداخل المؤسسة
          if (auth.isCompany) ...[
            _tile(
              context,
              icon: Icons.business_outlined,
              label: 'ملف المؤسسة',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
              ),
            ),
            _tile(
              context,
              icon: Icons.folder_shared_outlined,
              label: 'عروضي',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyJobsScreen()),
              ),
            ),
          ],

          const Divider(height: 24, indent: 16, endIndent: 16),

          _tile(
            context,
            icon: Icons.lock_outline_rounded,
            label: 'تغيير كلمة المرور',
            onTap: () => _changePassword(context),
          ),
          _tile(
            context,
            icon: Icons.logout_rounded,
            label: 'تسجيل الخروج',
            color: AppColors.danger,
            onTap: () => _logout(context),
          ),
          _tile(
            context,
            icon: Icons.delete_forever_outlined,
            label: 'حذف الحساب نهائيًا',
            color: AppColors.danger,
            onTap: () => _deleteAccount(context),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'معًا نحو مستقبل أفضل',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(Icons.chevron_left_rounded,
            color: AppColors.textMuted, size: 22),
        onTap: onTap,
      );

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'كلمة المرور الحالية'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'كلمة المرور الجديدة'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
            child: const Text('تغيير'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    try {
      await AuthService.changePassword(currentCtrl.text, newCtrl.text);
      if (context.mounted) showSnack(context, 'تم تغيير كلمة المرور');
    } on ApiException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final passwordCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب نهائيًا'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'سيُحذف حسابك وبياناتك الشخصية نهائيًا ولا يمكن التراجع عن ذلك.',
              style: TextStyle(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'كلمة المرور للتأكيد'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(90, 44),
            ),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await AuthService.deleteAccount(passwordCtrl.text);
      if (!context.mounted) return;
      await context.read<AuthProvider>().logout();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (context.mounted) showSnack(context, e.message, error: true);
    }
  }
}
