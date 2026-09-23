import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahth_aan_amal_dz/core/theme/app_theme.dart';
import 'package:bahth_aan_amal_dz/core/theme/company_theme.dart';

/// حساب تباين WCAG بين لونين (1 = متطابق، 21 = أقصى تباين)
double _contrast(Color a, Color b) {
  double lum(Color c) {
    // c.r/g/b تعود بقيم 0..1 في النسخ الحديثة من Flutter
    double ch(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final l1 = lum(a), l2 = lum(b);
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('الشريط العلوي لا يكون نصًّا أبيض على خلفية بيضاء', () {
    test('سمة الباحث: خلفية الشريط ليست شفّافة ولا بيضاء', () {
      final bar = AppTheme.light().appBarTheme;

      expect(bar.backgroundColor, isNotNull,
          reason: 'خلفية غير محدّدة تعني السقوط إلى الأبيض');
      expect(bar.backgroundColor, isNot(Colors.transparent));
      expect(bar.backgroundColor, isNot(Colors.white));
    });

    test('سمة الباحث: تباين كافٍ بين نص الشريط وخلفيته', () {
      final bar = AppTheme.light().appBarTheme;
      final fg = bar.foregroundColor ?? Colors.white;
      final bg = bar.backgroundColor!;

      // 4.5 هو حدّ WCAG AA للنصّ العادي
      expect(_contrast(fg, bg), greaterThan(4.5),
          reason: 'النص غير مقروء على خلفية الشريط');
    });

    test('سمة المؤسسة: خلفية خاصّة بها ومقروءة', () {
      final bar = CompanyTheme.build().appBarTheme;
      final fg = bar.foregroundColor ?? Colors.white;
      final bg = bar.backgroundColor!;

      expect(bg, isNot(Colors.transparent));
      expect(bg, isNot(Colors.white));
      // لون المؤسسة يختلف عن لون الباحث
      expect(bg, isNot(AppTheme.light().appBarTheme.backgroundColor));
      expect(_contrast(fg, bg), greaterThan(4.5));
    });
  });

  group('الهويّتان مختلفتان بصريًا', () {
    test('اللون الأساسي للمؤسسة يختلف عن لون الباحث', () {
      expect(CompanyColors.primary, isNot(AppColors.primary));
    });
  });

  testWidgets('الشريط العلوي يُرسم بخلفية مرئية فعلًا', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: null,
            body: SizedBox(),
          ),
        ),
      ),
    );

    // شاشة بشريط علوي عادي دون flexibleSpace
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(title: const Text('عنوان')),
            body: const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(Material),
          )
          .first,
    );

    expect(material.color, isNotNull);
    expect(material.color, isNot(Colors.transparent));
    expect(material.color, isNot(Colors.white));
  });
}
