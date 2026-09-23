import 'package:flutter/material.dart';

import 'app_theme.dart';

/// هوية بصرية مستقلّة لجانب المؤسسات.
///
/// الباحث عن عمل يستعمل الأزرق الكحلي؛ المؤسسة تستعمل الأخضر المزرقّ
/// (teal/emerald) حتى يعرف المستخدم فورًا في أي جانب من المنصّة هو.
class CompanyColors {
  CompanyColors._();

  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF0B5750);
  static const Color primaryLight = Color(0xFF14A79B);
  static const Color primarySoft = Color(0xFFE6F5F3);

  // لون ثانوي دافئ للأرقام والعناصر المميّزة
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentSoft = Color(0xFFFFF4E0);

  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF14A79B), Color(0xFF0F766E)],
  );

  static const LinearGradient gradientDeep = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F766E), Color(0xFF0B5750)],
  );

  /// ألوان بطاقات الإحصائيات في لوحة المؤسسة
  static const Color statBlue = Color(0xFF2F6FED);
  static const Color statPurple = Color(0xFF8B5CF6);
  static const Color statAmber = Color(0xFFF59E0B);
  static const Color statRose = Color(0xFFE11D48);
}

/// السمة الكاملة لجانب المؤسسة — تُبنى فوق سمة التطبيق مع تبديل
/// الألوان الأساسية، حتى تبقى المسافات والخطوط والحركة موحّدة.
class CompanyTheme {
  CompanyTheme._();

  static ThemeData build() {
    final base = AppTheme.light();

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: CompanyColors.primary,
        secondary: CompanyColors.accent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: base.elevatedButtonTheme.style?.copyWith(
          backgroundColor:
              WidgetStateProperty.all(CompanyColors.primary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
          foregroundColor:
              WidgetStateProperty.all(CompanyColors.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          foregroundColor:
              WidgetStateProperty.all(CompanyColors.primary),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:
              const BorderSide(color: CompanyColors.primary, width: 1.8),
        ),
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        selectedItemColor: CompanyColors.primary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: CompanyColors.primary,
        linearTrackColor: AppColors.border,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? CompanyColors.primary
                : AppColors.borderStrong),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}

/// يلفّ أي شاشة بجانب المؤسسة بالسمة الخاصّة بها
class CompanyScope extends StatelessWidget {
  final Widget child;
  const CompanyScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      Theme(data: CompanyTheme.build(), child: child);
}
