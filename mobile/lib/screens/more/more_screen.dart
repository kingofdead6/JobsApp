import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../company/companies_screen.dart';
import '../jobs/jobs_list_screen.dart';
import '../jobs/wilaya_jobs_screen.dart';
import '../saved/saved_screen.dart';

/// تبويب «المزيد» — روابط عامة وصفحات ثابتة
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
          title: const Text('المزيد'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _sectionTitle('التصفّح'),
          _tile(context,
              icon: Icons.search_rounded,
              label: 'البحث عن عمل',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const JobsListScreen()))),
          _tile(context,
              icon: Icons.star_rounded,
              label: 'العروض المميّزة',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const JobsListScreen(featuredOnly: true)))),
          _tile(context,
              icon: Icons.location_on_rounded,
              label: 'وظائف حسب الولاية',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WilayaJobsScreen()))),
          _tile(context,
              icon: Icons.business_rounded,
              label: 'الشركات',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CompaniesScreen()))),
          if (auth.isSeeker)
            _tile(context,
                icon: Icons.bookmark_rounded,
                label: 'المحفوظات',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SavedScreen()))),

          const Divider(height: 24, indent: 16, endIndent: 16),
          _sectionTitle('عن التطبيق'),

          _tile(context,
              icon: Icons.privacy_tip_outlined,
              label: 'سياسة الخصوصية',
              onTap: () => _showPolicy(context)),
          _tile(context,
              icon: Icons.gavel_rounded,
              label: 'الشروط والأحكام',
              onTap: () => _showTerms(context)),
          _tile(context,
              icon: Icons.support_agent_rounded,
              label: 'تواصل معنا',
              onTap: () => _showContact(context)),
          _tile(context,
              icon: Icons.info_outline_rounded,
              label: 'عن التطبيق',
              onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'بحث عن عمل DZ',
                    applicationVersion: 'الإصدار 1.0.0',
                    applicationIcon: const Padding(
                      padding: EdgeInsets.all(8),
                      child: AppLogo(size: 48, light: false),
                    ),
                    children: const [
                      Text(
                        'منصّة التشغيل الجزائرية التي تربط الباحثين عن عمل '
                        'بأصحاب المؤسسات في كل الولايات الـ58.',
                        style: TextStyle(fontSize: 13, height: 1.7),
                      ),
                    ],
                  )),

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

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
      );

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(label,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_left_rounded,
            color: AppColors.textMuted, size: 22),
        onTap: onTap,
      );

  void _showPolicy(BuildContext context) => _showText(
        context,
        'سياسة الخصوصية',
        'نلتزم بحماية معطياتك الشخصية وفق القانون 18-07 المتعلّق بحماية '
            'الأشخاص الطبيعيين في مجال معالجة المعطيات ذات الطابع الشخصي.\n\n'
            '• لا نبيع بياناتك لأي طرف ثالث.\n'
            '• نجمع الحد الأدنى من المعطيات اللازمة لتشغيل الخدمة.\n'
            '• يحقّ لك الاطّلاع على بياناتك وتعديلها وحذفها في أي وقت.\n'
            '• تُخزَّن كلمات المرور مشفّرة، وتمرّ كل الاتصالات عبر HTTPS.\n'
            '• يمكنك حذف حسابك نهائيًا من شاشة «حسابي».',
      );

  void _showTerms(BuildContext context) => _showText(
        context,
        'الشروط والأحكام',
        'باستعمالك للتطبيق فإنك توافق على ما يلي:\n\n'
            '• التطبيق مجاني للباحثين عن عمل.\n'
            '• تُراجَع كل عروض العمل من طرف المشرف قبل نشرها.\n'
            '• يُمنع نشر عروض وهمية أو طلب مال من المترشّحين.\n'
            '• لا نطلب منك أبدًا دفع مبلغ مقابل التوظيف؛ أبلغ عن أي عرض '
            'يطلب ذلك.\n'
            '• المنصّة وسيط ولا تتحمّل مسؤولية العلاقة التعاقدية بين الطرفين.',
      );

  void _showContact(BuildContext context) => _showText(
        context,
        'تواصل معنا',
        'نسعد باستقبال ملاحظاتك واقتراحاتك.\n\n'
            'البريد الإلكتروني: contact@bahth-dz.example\n'
            'الهاتف: 0XX XX XX XX\n\n'
            'للإبلاغ عن عرض مشبوه، استعمل زر «الإبلاغ» داخل صفحة العرض.',
      );

  void _showText(BuildContext context, String title, String body) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          expand: false,
          builder: (context, controller) => Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Text(
                  body,
                  style: const TextStyle(fontSize: 13.5, height: 1.9),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
}
