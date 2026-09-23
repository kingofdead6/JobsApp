import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../auth/welcome_screen.dart';
import '../company/company_detail_screen.dart';

/// تفاصيل العرض والترشّح (3.4)
class JobDetailScreen extends StatefulWidget {
  final String offerId;
  const JobDetailScreen({super.key, required this.offerId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  JobOffer? _offer;
  bool _isSaved = false;
  bool _hasApplied = false;
  bool _loading = true;
  bool _applying = false;
  String? _error;

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
      final data = await JobService.detail(widget.offerId);
      if (!mounted) return;
      setState(() {
        _offer = data['offer'] as JobOffer;
        _isSaved = data['isSaved'] as bool;
        _hasApplied = data['hasApplied'] as bool;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  bool _requireLogin() {
    if (context.read<AuthProvider>().isAuthenticated) return false;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(PhosphorIcons.userCircle(PhosphorIconsStyle.duotone),
            size: 46, color: AppColors.primary),
        title: const Text('تسجيل الدخول مطلوب',
            textAlign: TextAlign.center),
        content: const Text(
          'يجب تسجيل الدخول للقيام بهذا الإجراء.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()));
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(110, 46)),
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
    return true;
  }

  Future<void> _toggleSave() async {
    if (_requireLogin()) return;
    final next = !_isSaved;
    setState(() => _isSaved = next); // تفاؤلي: نستجيب فورًا
    try {
      if (next) {
        await SavedService.saveOffer(widget.offerId);
      } else {
        await SavedService.unsaveOffer(widget.offerId);
      }
      if (mounted) {
        showSnack(context, next ? 'تم حفظ العرض' : 'تم إلغاء الحفظ');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaved = !next); // تراجع عند الفشل
      showSnack(context, e.message, error: true);
    }
  }

  Future<void> _apply() async {
    if (_requireLogin()) return;
    if (!context.read<AuthProvider>().isSeeker) {
      showSnack(context, 'الترشّح متاح لحسابات الباحثين عن عمل فقط',
          error: true);
      return;
    }

    final coverLetter = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CoverLetterSheet(),
    );
    if (coverLetter == null) return;

    setState(() => _applying = true);
    try {
      await ApplicationService.apply(widget.offerId,
          coverLetter: coverLetter);
      if (!mounted) return;
      setState(() {
        _hasApplied = true;
        _applying = false;
      });
      _showSuccessDialog();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _applying = false);
      showSnack(context, e.message, error: true);
    }
  }

  void _showSuccessDialog() => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.successSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                size: 42, color: AppColors.success),
          ),
          title: const Text('تم إرسال طلبك', textAlign: TextAlign.center),
          content: const Text(
            'أُرسلت سيرتك الذاتية إلى المؤسسة. ستصلك إشعارات بتغيّر حالة الطلب.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.7),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );

  Future<void> _report() async {
    if (_requireLogin()) return;
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReportSheet(),
    );
    if (reason == null) return;

    try {
      await MiscService.report(
        targetType: 'offer',
        targetId: widget.offerId,
        reason: reason,
      );
      if (mounted) showSnack(context, 'تم استلام بلاغك، شكرًا لك');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  void _share() {
    final o = _offer;
    if (o == null) return;
    Share.share(
      '${o.title}\n${o.company?.name ?? ''} — ${o.wilaya}\n'
      '${Labels.contract(o.contractType)} · ${o.salaryLabel}\n\n'
      'عبر تطبيق بحث عن عمل DZ',
      subject: o.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: gradientAppBar('تفاصيل الوظيفة'),
        body: const Loader(),
      );
    }
    if (_error != null || _offer == null) {
      return Scaffold(
        appBar: gradientAppBar('تفاصيل الوظيفة'),
        body: ErrorState(message: _error ?? 'العرض غير موجود', onRetry: _load),
      );
    }

    final o = _offer!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 268,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: Icon(PhosphorIcons.arrowRight(PhosphorIconsStyle.bold)),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                onPressed: _share,
                icon: Icon(PhosphorIcons.shareNetwork(
                    PhosphorIconsStyle.bold)),
                tooltip: 'مشاركة',
              ),
              IconButton(
                onPressed: _toggleSave,
                icon: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: Icon(
                    _isSaved
                        ? PhosphorIcons.bookmarkSimple(
                            PhosphorIconsStyle.fill)
                        : PhosphorIcons.bookmarkSimple(
                            PhosphorIconsStyle.regular),
                    key: ValueKey(_isSaved),
                  ),
                ),
                tooltip: _isSaved ? 'إلغاء الحفظ' : 'حفظ العرض',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _headerContent(o),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(child: _salaryCard(o)),
                  const SizedBox(height: 16),
                  FadeInUp(index: 1, child: _quickFacts(o)),
                  const SizedBox(height: 22),

                  FadeInUp(
                    index: 2,
                    child: _section(
                      'وصف الوظيفة',
                      PhosphorIcons.textAlignRight(PhosphorIconsStyle.bold),
                      child: Text(
                        o.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  if (o.skills.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    FadeInUp(
                      index: 3,
                      child: _section(
                        'المهارات المطلوبة',
                        PhosphorIcons.checkSquare(PhosphorIconsStyle.bold),
                        child: Column(
                          children: o.skills
                              .map((s) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(
                                              top: 2),
                                          padding:
                                              const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: AppColors.successSoft,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            PhosphorIcons.check(
                                                PhosphorIconsStyle.bold),
                                            size: 11,
                                            color: AppColors.success,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            s,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              height: 1.6,
                                              color:
                                                  AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  FadeInUp(index: 4, child: _companyCard(o)),

                  const SizedBox(height: 22),
                  Center(
                    child: TextButton.icon(
                      onPressed: _report,
                      icon: Icon(PhosphorIcons.flag(PhosphorIconsStyle.bold),
                          size: 16, color: AppColors.danger),
                      label: const Text(
                        'الإبلاغ عن هذا العرض',
                        style: TextStyle(
                            color: AppColors.danger, fontSize: 12.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomSheet: _applyBar(),
    );
  }

  Widget _headerContent(JobOffer o) => Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Hero(
                      tag: 'offer-avatar-${o.id}',
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                          boxShadow: AppShadows.lifted,
                        ),
                        child: CompanyAvatar(
                            company: o.company, sector: o.sector, size: 58),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      o.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            o.company?.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13.5),
                          ),
                        ),
                        if (o.company?.isVerified ?? false) ...[
                          const SizedBox(width: 5),
                          Icon(
                              PhosphorIcons.sealCheck(
                                  PhosphorIconsStyle.fill),
                              size: 15,
                              color: Colors.white),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _headerPill(
                          PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
                          o.wilaya,
                        ),
                        const SizedBox(width: 8),
                        _headerPill(
                          ContractChip.iconFor(o.contractType),
                          Labels.contract(o.contractType),
                          bg: AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _headerPill(IconData icon, String text, {Color? bg}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: bg ?? Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  Widget _salaryCard(JobOffer o) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.successSoft,
              AppColors.successSoft.withValues(alpha: 0.45),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
              color: AppColors.success.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                boxShadow: AppShadows.colored(AppColors.success),
              ),
              child: Icon(PhosphorIcons.money(PhosphorIconsStyle.fill),
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 13),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الراتب الشهري',
                  style: TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  o.salaryLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _quickFacts(JobOffer o) => Row(
        children: [
          if (o.educationLevel != null)
            Expanded(
              child: _factCard(
                PhosphorIcons.graduationCap(PhosphorIconsStyle.fill),
                'المستوى',
                Labels.education(o.educationLevel),
                AppColors.tilePurple,
              ),
            ),
          if (o.educationLevel != null && o.experienceLevel != null)
            const SizedBox(width: 10),
          if (o.experienceLevel != null)
            Expanded(
              child: _factCard(
                PhosphorIcons.briefcase(PhosphorIconsStyle.fill),
                'الخبرة',
                Labels.experience(o.experienceLevel),
                AppColors.tileBlue,
              ),
            ),
          if (o.educationLevel == null && o.experienceLevel == null)
            Expanded(
              child: _factCard(
                PhosphorIcons.tag(PhosphorIconsStyle.fill),
                'القطاع',
                Labels.sector(o.sector),
                AppColors.tileOrange,
              ),
            ),
        ],
      );

  Widget _factCard(IconData icon, String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ],
        ),
      );

  Widget _section(String title, IconData icon, {required Widget child}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      );

  Widget _companyCard(JobOffer o) {
    final c = o.company;
    if (c == null) return const SizedBox.shrink();

    return PressableScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CompanyDetailScreen(companyId: c.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CompanyAvatar(company: c, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (c.isVerified) ...[
                        const SizedBox(width: 5),
                        const VerifiedBadge(size: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'عرض صفحة المؤسسة وعروضها',
                    style: TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                size: 17, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _applyBar() => Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: AppShadows.lifted,
        ),
        child: _hasApplied
            ? Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                        color: AppColors.success,
                        size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'تم إرسال طلبك لهذا العرض',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : PressableScale(
                onTap: _applying ? null : _apply,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadows.colored(AppColors.primary),
                  ),
                  child: Center(
                    child: _applying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  PhosphorIcons.paperPlaneTilt(
                                      PhosphorIconsStyle.fill),
                                  color: Colors.white,
                                  size: 19),
                              const SizedBox(width: 9),
                              const Text(
                                'تقديم الطلب',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
      );
}

/// رسالة تحفيزية اختيارية قبل إرسال الطلب
class _CoverLetterSheet extends StatefulWidget {
  const _CoverLetterSheet();

  @override
  State<_CoverLetterSheet> createState() => _CoverLetterSheetState();
}

class _CoverLetterSheetState extends State<_CoverLetterSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill),
                      color: AppColors.primary,
                      size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'تقديم الطلب',
                    style: TextStyle(
                        fontSize: 17.5, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              const Text(
                'سترسل سيرتك الذاتية الرقمية مع هذا الطلب',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _ctrl,
                maxLines: 5,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText: 'رسالة تحفيزية (اختيارية)...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
                icon: Icon(
                    PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill),
                    size: 18),
                label: const Text('إرسال الطلب'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        ),
      );
}

/// أسباب الإبلاغ عن عرض مشبوه
class _ReportSheet extends StatelessWidget {
  const _ReportSheet();

  static IconData _iconFor(String key) => switch (key) {
        'fake' => PhosphorIcons.prohibit(PhosphorIconsStyle.bold),
        'scam' => PhosphorIcons.warningOctagon(PhosphorIconsStyle.bold),
        'money_request' => PhosphorIcons.currencyCircleDollar(
            PhosphorIconsStyle.bold),
        'offensive' => PhosphorIcons.smileyXEyes(PhosphorIconsStyle.bold),
        'duplicate' => PhosphorIcons.copy(PhosphorIconsStyle.bold),
        _ => PhosphorIcons.dotsThreeCircle(PhosphorIconsStyle.bold),
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 12, top: 10),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.flag(PhosphorIconsStyle.fill),
                    color: AppColors.danger, size: 19),
                const SizedBox(width: 8),
                const Text(
                  'سبب الإبلاغ',
                  style:
                      TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            ...Labels.reportReasons.entries.map(
              (e) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(_iconFor(e.key),
                      size: 16, color: AppColors.danger),
                ),
                title: Text(e.value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: Icon(
                    PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                    size: 15,
                    color: AppColors.textMuted),
                onTap: () => Navigator.pop(context, e.key),
              ),
            ),
          ],
        ),
      );
}
