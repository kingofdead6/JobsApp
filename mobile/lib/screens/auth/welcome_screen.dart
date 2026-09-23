import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// شاشة «مرحبًا بك» — الواجهة الأولى للزائر غير المسجّل
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // نصف علوي متدرّج يحمل الشعار
          Container(
            height: MediaQuery.of(context).size.height * 0.46,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradientDeep,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(34)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  left: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CustomPaint(
                    size: const Size(double.infinity, 70),
                    painter: SkylinePainter(opacity: 0.13),
                  ),
                ),
                const Center(
                  child: FadeInUp(child: AppLogo(size: 96, showTagline: true)),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.46),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                    child: Column(
                      children: [
                        const FadeInUp(
                          index: 1,
                          child: Text(
                            'مرحبًا بك',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        const FadeInUp(
                          index: 2,
                          child: Text(
                            'سجّل الدخول أو أنشئ حسابًا جديدًا للبدء',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        FadeInUp(
                          index: 3,
                          child: _PrimaryButton(
                            label: 'تسجيل الدخول',
                            icon: PhosphorIcons.signIn(
                                PhosphorIconsStyle.bold),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeInUp(
                          index: 4,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            ),
                            icon: Icon(
                                PhosphorIcons.userPlus(
                                    PhosphorIconsStyle.bold),
                                size: 19),
                            label: const Text('إنشاء حساب جديد'),
                          ),
                        ),

                        const SizedBox(height: 26),
                        FadeInUp(index: 5, child: _divider()),
                        const SizedBox(height: 20),

                        FadeInUp(
                          index: 6,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SocialButton(
                                label: 'Google',
                                color: const Color(0xFFDB4437),
                                icon: PhosphorIcons.googleLogo(
                                    PhosphorIconsStyle.bold),
                                onTap: () => _notAvailable(context),
                              ),
                              const SizedBox(width: 14),
                              _SocialButton(
                                label: 'Facebook',
                                color: const Color(0xFF1877F2),
                                icon: PhosphorIcons.facebookLogo(
                                    PhosphorIconsStyle.fill),
                                onTap: () => _notAvailable(context),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),
                        FadeInUp(
                          index: 7,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  PhosphorIcons.shieldCheck(
                                      PhosphorIconsStyle.fill),
                                  size: 15,
                                  color: AppColors.success),
                              const SizedBox(width: 6),
                              const Text(
                                'آمن وموثوق · مجاني للباحثين عن عمل',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'معًا نحو مستقبل أفضل',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
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

  static Widget _divider() => const Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'أو تابع عبر',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          ),
          Expanded(child: Divider()),
        ],
      );

  static void _notAvailable(BuildContext context) => showSnack(
        context,
        'تسجيل الدخول عبر الشبكات الاجتماعية سيتوفّر قريبًا',
        error: true,
      );
}

/// زر أساسي بتدرّج وظلّ ملوّن
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => PressableScale(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.colored(AppColors.primary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 9),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
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
        child: PressableScale(
          onTap: onTap,
          scale: 0.93,
          child: Container(
            width: 74,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
        ),
      );
}
