import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/common.dart';
import 'auth/welcome_screen.dart';
import 'main_shell.dart';

/// شاشة البداية — الشعار يدخل بتكبير لطيف فوق تدرّج أزرق
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _glowC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _decideNext();
  }

  @override
  void dispose() {
    _logoC.dispose();
    _glowC.dispose();
    super.dispose();
  }

  Future<void> _decideNext() async {
    await Future.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    // ننتظر انتهاء استعادة الجلسة
    while (auth.status == AuthStatus.unknown) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
    if (!mounted) return;

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: AppMotion.slow,
      pageBuilder: (_, __, ___) =>
          auth.isAuthenticated ? const MainShell() : const WelcomeScreen(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _logoC, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: _logoC, curve: Curves.easeOut);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradientDeep,
        ),
        child: Stack(
          children: [
            // هالة نابضة خلف الشعار
            Center(
              child: AnimatedBuilder(
                animation: _glowC,
                builder: (_, __) => Container(
                  width: 250 + (_glowC.value * 40),
                  height: 250 + (_glowC.value * 40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold
                            .withValues(alpha: 0.10 + _glowC.value * 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Center(
              child: FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.72, end: 1).animate(scale),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AppLogo(size: 116, showTagline: true),
                      const SizedBox(height: 40),
                      _FlagDZ(fade: fade),
                    ],
                  ),
                ),
              ),
            ),

            // مؤشّر تحميل خفيف أسفل الشاشة
            Positioned(
              left: 0,
              right: 0,
              bottom: 132,
              child: FadeTransition(
                opacity: fade,
                child: const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.goldLight),
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomPaint(
                size: const Size(double.infinity, 118),
                painter: SkylinePainter(opacity: 0.14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// علم الجزائر مرسوم بدل استعمال صورة
class _FlagDZ extends StatelessWidget {
  final Animation<double> fade;
  const _FlagDZ({required this.fade});

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: fade,
        child: Container(
          width: 52,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24),
            boxShadow: AppShadows.soft,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(child: Container(color: const Color(0xFF006233))),
              Expanded(
                child: Container(
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: const Text(
                    '☾',
                    style: TextStyle(color: Color(0xFFD21034), fontSize: 17),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
