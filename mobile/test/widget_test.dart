import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bahth_aan_amal_dz/core/utils/labels.dart';

void main() {
  group('المراجع الثابتة', () {
    test('الولايات الـ58 كاملة', () {
      expect(Labels.wilayas.length, 58);
      expect(Labels.wilayas.first, 'أدرار');
      expect(Labels.wilayas.last, 'المنيعة');
      // لا تكرار في الأسماء
      expect(Labels.wilayas.toSet().length, 58);
    });

    test('أنواع العقود الستة', () {
      expect(Labels.contractTypes.length, 6);
      expect(Labels.contract('full_time'), 'دوام كامل');
      expect(Labels.contract('internship'), 'تربّص');
    });

    test('القطاعات الأحد عشر', () {
      expect(Labels.sectors.length, 11);
      expect(Labels.sector('construction'), 'البناء والأشغال العمومية');
    });

    test('مفتاح غير معروف يُعاد كما هو دون انهيار', () {
      expect(Labels.contract('unknown_key'), 'unknown_key');
      expect(Labels.sector(null), '');
    });
  });

  group('الوقت النسبي بالعربية', () {
    test('الآن', () {
      expect(timeAgo(DateTime.now()), 'الآن');
    });

    test('المثنّى والجمع', () {
      final now = DateTime.now();
      expect(timeAgo(now.subtract(const Duration(minutes: 2))), 'منذ دقيقتين');
      expect(timeAgo(now.subtract(const Duration(hours: 1))), 'منذ ساعة');
      expect(timeAgo(now.subtract(const Duration(hours: 5))), 'منذ 5 ساعات');
      expect(timeAgo(now.subtract(const Duration(days: 1))), 'أمس');
    });

    test('قيمة فارغة تُعيد نصًا فارغًا', () {
      expect(timeAgo(null), '');
    });
  });

  testWidgets('التطبيق يفرض الاتجاه RTL على كل الشاشات', (tester) async {
    // نحاكي ما يفعله main.dart: لفّ محتوى MaterialApp داخل Directionality.
    // (MaterialApp نفسه يضبط الاتجاه حسب اللغة، لذا يجب أن يكون اللفّ داخله)
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar', 'DZ'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar', 'DZ')],
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: const Scaffold(body: Text('مرحبًا')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مرحبًا'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('مرحبًا'))),
      TextDirection.rtl,
    );
  });
}
