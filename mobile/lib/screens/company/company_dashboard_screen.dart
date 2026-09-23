import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/company_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../../widgets/company_widgets.dart';
import 'company_profile_screen.dart';
import 'my_jobs_screen.dart';
import 'offer_applicants_screen.dart';
import 'post_job_screen.dart';

/// لوحة المؤسسة — الشاشة الرئيسية لجانب أصحاب العمل.
/// تختلف كليًا عن واجهة الباحث: إحصائيات، إجراءات سريعة، آخر العروض.
class CompanyDashboardScreen extends StatefulWidget {
  final void Function(int)? onNavigateTab;
  const CompanyDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<JobOffer> _offers = [];
  bool _loading = true;
  String? _error;
  bool _noCompany = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await CompanyService.stats();
      final offers = await JobService.mine();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _offers = offers;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        // 404 يعني أن ملف المؤسسة لم يُنشأ بعد
        _noCompany = e.statusCode == 404;
        _error = _noCompany ? null : e.message;
        _loading = false;
      });
    }
  }

  int _byStatus(String key) {
    final m = _stats?['offersByStatus'];
    if (m is Map) return (m[key] ?? 0) as int;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (_loading) {
      return const Scaffold(body: Loader());
    }

    if (_noCompany) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.business_rounded,
          title: 'أنشئ ملف مؤسستك',
          subtitle:
              'لا يمكنك نشر عروض العمل أو استقبال الترشّحات قبل إنشاء ملف المؤسسة.',
          action: SizedBox(
            width: 220,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
              ).then((_) => _load()),
              icon: const Icon(Icons.add_business_rounded, size: 19),
              label: const Text('إنشاء الملف'),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(body: ErrorState(message: _error!, onRetry: _load));
    }

    final totalOffers = _offers.length;
    final pendingApplicants =
        _offers.fold<int>(0, (sum, o) => sum + o.applicationsCount);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostJobScreen()),
        ).then((_) => _load()),
        backgroundColor: CompanyColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('عرض جديد',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: CompanyColors.primary,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _header(auth),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(child: _statsGrid()),
                  const SizedBox(height: 24),
                  const FadeInUp(
                    index: 1,
                    child: CompanySectionTitle(
                      title: 'إجراءات سريعة',
                      icon: Icons.bolt_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(index: 2, child: _quickActions(pendingApplicants)),
                  const SizedBox(height: 24),
                  FadeInUp(
                    index: 3,
                    child: CompanySectionTitle(
                      title: 'توزيع العروض',
                      icon: Icons.donut_small_rounded,
                      trailing: Text(
                        'المجموع $totalOffers',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(index: 4, child: _distribution(totalOffers)),
                  const SizedBox(height: 24),
                  FadeInUp(
                    index: 5,
                    child: CompanySectionTitle(
                      title: 'آخر عروضك',
                      icon: Icons.work_rounded,
                      trailing: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MyJobsScreen()),
                        ).then((_) => _load()),
                        child: const Text('الكل',
                            style: TextStyle(fontSize: 12.5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_offers.isEmpty)
                    _emptyOffers()
                  else
                    ..._offers.take(4).toList().asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FadeInUp(
                              index: 6 + e.key,
                              child: _offerRow(e.value),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(AuthProvider auth) {
    final company = auth.company;
    final verified = company?.isVerified ?? false;

    return CompanyHeader(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: CompanyAvatar(company: company, size: 42),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company?.name ?? 'مؤسستي',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          verified
                              ? Icons.verified_rounded
                              : Icons.gpp_maybe_rounded,
                          size: 13,
                          color: verified ? Colors.white : CompanyColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          verified ? 'مؤسسة موثّقة' : 'غير موثّقة',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: verified
                                ? Colors.white70
                                : CompanyColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => widget.onNavigateTab?.call(3),
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white),
                tooltip: 'الإشعارات',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'لوحة المؤسسة',
            style: TextStyle(
                color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'تابع عروضك والترشّحات الواردة',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid() => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
        children: [
          StatCard(
            icon: Icons.visibility_rounded,
            label: 'مجموع المشاهدات',
            value: (_stats?['totalViews'] ?? 0) as int,
            color: CompanyColors.statBlue,
          ),
          StatCard(
            icon: Icons.people_rounded,
            label: 'مجموع الترشّحات',
            value: (_stats?['totalApplications'] ?? 0) as int,
            color: CompanyColors.statPurple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyJobsScreen()),
            ),
          ),
          StatCard(
            icon: Icons.check_circle_rounded,
            label: 'عروض منشورة',
            value: _byStatus('approved'),
            color: AppColors.success,
          ),
          StatCard(
            icon: Icons.hourglass_top_rounded,
            label: 'قيد المراجعة',
            value: _byStatus('pending'),
            color: CompanyColors.statAmber,
          ),
        ],
      );

  Widget _quickActions(int applicants) => Column(
        children: [
          QuickAction(
            icon: Icons.add_circle_rounded,
            label: 'نشر عرض عمل',
            subtitle: 'معالج من ثلاث خطوات',
            color: CompanyColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PostJobScreen()),
            ).then((_) => _load()),
          ),
          const SizedBox(height: 10),
          QuickAction(
            icon: Icons.people_rounded,
            label: 'الترشّحات الواردة',
            subtitle: 'راجع المترشّحين واقبل أو ارفض',
            color: CompanyColors.statPurple,
            badge: applicants,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyJobsScreen()),
            ).then((_) => _load()),
          ),
          const SizedBox(height: 10),
          QuickAction(
            icon: Icons.business_rounded,
            label: 'ملف المؤسسة',
            subtitle: 'الشعار، الوصف، طلب التوثيق',
            color: CompanyColors.statBlue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
            ).then((_) => _load()),
          ),
        ],
      );

  Widget _distribution(int total) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: total == 0
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'لا توجد عروض بعد',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              )
            : Column(
                children: [
                  StatBar(
                    label: 'منشورة',
                    value: _byStatus('approved'),
                    total: total,
                    color: AppColors.success,
                  ),
                  StatBar(
                    label: 'قيد المراجعة',
                    value: _byStatus('pending'),
                    total: total,
                    color: AppColors.warning,
                  ),
                  StatBar(
                    label: 'مرفوضة',
                    value: _byStatus('rejected'),
                    total: total,
                    color: AppColors.danger,
                  ),
                  StatBar(
                    label: 'موقوفة أو منتهية',
                    value: _byStatus('paused') + _byStatus('expired'),
                    total: total,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
      );

  Widget _emptyOffers() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.work_off_rounded, size: 38, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'لم تنشر أي عرض بعد',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text(
              'انشر عرضك الأول ليصل إلى آلاف الباحثين عن عمل',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      );

  Widget _offerRow(JobOffer o) {
    final color = switch (o.status) {
      'approved' => AppColors.success,
      'pending' => AppColors.warning,
      'rejected' => AppColors.danger,
      _ => AppColors.textMuted,
    };

    return PressableScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OfferApplicantsScreen(offerId: o.id, offerTitle: o.title),
        ),
      ).then((_) => _load()),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    o.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                ),
                StatusPill(label: Labels.offer(o.status), color: color),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _metric(Icons.visibility_rounded, o.viewsCount, 'مشاهدة'),
                const SizedBox(width: 16),
                _metric(Icons.people_rounded, o.applicationsCount, 'ترشّح'),
                const Spacer(),
                const Icon(Icons.chevron_left_rounded,
                    size: 18, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(IconData icon, int value, String label) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      );
}
