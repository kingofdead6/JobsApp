import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const BahthApp());
}

class BahthApp extends StatelessWidget {
  const BahthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..bootstrap()),
      ],
      child: MaterialApp(
        title: 'بحث عن عمل DZ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),

        // اللغة الأساسية: العربية باتجاه RTL في كل الشاشات (الفصل 5)
        locale: const Locale('ar', 'DZ'),
        supportedLocales: const [Locale('ar', 'DZ'), Locale('fr', 'FR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        builder: (context, child) {
          // فرض الاتجاه من اليمين إلى اليسار، وتثبيت مقياس الخط
          // ضمن حدود معقولة حتى لا تنكسر الواجهة عند التكبير
          final scale = MediaQuery.textScalerOf(context).scale(1.0).clamp(0.85, 1.4);
          return Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          );
        },

        home: const SplashScreen(),
      ),
    );
  }
}
