import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'company/company_shell.dart';
import 'main_shell.dart';

/// يوجّه المستخدم بعد الدخول إلى الهيكل المناسب لدوره:
/// المؤسسة ← هيكل المؤسسة، الباحث ← الهيكل العادي.
///
/// يُستعمل بدل استدعاء MainShell مباشرة حتى تبقى قاعدة التوجيه
/// في مكان واحد.
class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isCompany ? const CompanyShell() : const MainShell();
  }
}
