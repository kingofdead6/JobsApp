import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// شاشة «مرحبًا بك» — سجّل الدخول أو أنشئ حسابًا جديدًا
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const Spacer(flex: 2),
                const AppLogo(size: 92, light: false),
                const SizedBox(height: 32),
                const Text(
                  'مرحبًا بك',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'سجّل الدخول أو أنشئ حساب جديد',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        icon: const Icon(Icons.person_rounded),
                        label: const Text('تسجيل الدخول'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('إنشاء حساب جديد'),
                      ),
                      const SizedBox(height: 22),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'أو سجّل عبر',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialButton(
                            label: 'Google',
                            color: const Color(0xFFDB4437),
                            icon: Icons.g_mobiledata_rounded,
                            onTap: () => _notAvailable(context),
                          ),
                          const SizedBox(width: 16),
                          _SocialButton(
                            label: 'Facebook',
                            color: const Color(0xFF1877F2),
                            icon: Icons.facebook_rounded,
                            onTap: () => _notAvailable(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'معًا نحو مستقبل أفضل',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size(double.infinity, 70),
                  painter: SkylinePainter(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _notAvailable(BuildContext context) => showSnack(
        context,
        'تسجيل الدخول عبر الشبكات الاجتماعية سيتوفّر قريبًا',
        error: true,
      );
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'التسجيل عبر $label',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 64,
            height: 52,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
      );
}
