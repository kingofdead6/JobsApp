import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ألوان الهوية البصرية — مستوحاة من نموذج التصميم ومطوَّرة
/// بتدرّجات وظلال تمنح الواجهة عمقًا وحيوية.
class AppColors {
  AppColors._();

  // الأزرق الكحلي الأساسي
  static const Color primary = Color(0xFF0B3C87);
  static const Color primaryDark = Color(0xFF062A63);
  static const Color primaryLight = Color(0xFF1D5FBF);
  static const Color primarySoft = Color(0xFFEAF1FC);

  // الذهبي — لكلمة «عمل» والعناصر المميّزة
  static const Color gold = Color(0xFFF5B301);
  static const Color goldLight = Color(0xFFFFD34E);
  static const Color goldDark = Color(0xFFC98F00);
  static const Color goldSoft = Color(0xFFFFF6DE);

  // ألوان المداخل الستة
  static const Color tileGreen = Color(0xFF12A150);
  static const Color tileBlue = Color(0xFF2F6FED);
  static const Color tilePurple = Color(0xFF8B5CF6);
  static const Color tileOrange = Color(0xFFF97316);
  static const Color tileRed = Color(0xFFE11D48);
  static const Color tileTeal = Color(0xFF0D9488);

  // دلالية
  static const Color success = Color(0xFF12A150);
  static const Color successSoft = Color(0xFFE7F7EE);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFFF4E0);
  static const Color danger = Color(0xFFE02424);
  static const Color dangerSoft = Color(0xFFFDECEC);
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoSoft = Color(0xFFE5F6FE);

  // محايدة
  static const Color background = Color(0xFFF4F7FB);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF9FBFD);
  static const Color border = Color(0xFFE4EAF2);
  static const Color borderStrong = Color(0xFFCFD8E5);
  static const Color textPrimary = Color(0xFF0D1B33);
  static const Color textSecondary = Color(0xFF5E6E88);
  static const Color textMuted = Color(0xFF9AA8BF);

  /// تدرّج الترويسات والأزرار الأساسية
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF1D5FBF), Color(0xFF0B3C87)],
  );

  static const LinearGradient primaryGradientDeep = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B3C87), Color(0xFF062A63)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFFFFD34E), Color(0xFFF5B301)],
  );
}

/// ظلال متدرّجة بدل ظلّ واحد قاسٍ
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: const Color(0xFF0D1B33).withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF0D1B33).withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF0D1B33).withValues(alpha: 0.02),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get lifted => [
        BoxShadow(
          color: const Color(0xFF0D1B33).withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// ظلّ ملوّن يتبع لون العنصر (للأزرار والمداخل)
  static List<BoxShadow> colored(Color color, {double opacity = 0.32}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

/// أنصاف أقطار موحّدة
class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

/// مدد الحركة — قصيرة ومتّسقة حتى تبقى الواجهة سريعة
class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Curve curve = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
}

class AppTheme {
  AppTheme._();

  static const String? _fontFamily = null;

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: base.textTheme
          .apply(
            fontFamily: _fontFamily,
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          )
          .copyWith(
            titleLarge: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, height: 1.3),
            titleMedium: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, height: 1.35),
            bodyMedium: const TextStyle(fontSize: 14, height: 1.6),
            bodySmall: const TextStyle(
                fontSize: 12.5, height: 1.5, color: AppColors.textSecondary),
          ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 17.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          // هدف لمس ≥ 44 بكسل — إمكانية الوصول (الفصل 5)
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.borderStrong, width: 1.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
      ),

      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill)),
        labelStyle: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      dividerTheme:
          const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        contentTextStyle: const TextStyle(
            fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
        insetPadding: const EdgeInsets.all(16),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.borderStrong),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // انتقالات أنعم بين الصفحات
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: _FadeSlideTransitionBuilder(),
        TargetPlatform.iOS: _FadeSlideTransitionBuilder(),
      }),
    );
  }
}

/// انتقال صفحات: تلاشٍ مع انزلاق خفيف — أخفّ من الانزلاق الكامل
/// وأكثر أناقة على الهواتف المتوسطة.
class _FadeSlideTransitionBuilder extends PageTransitionsBuilder {
  const _FadeSlideTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved =
        CurvedAnimation(parent: animation, curve: AppMotion.curve);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
