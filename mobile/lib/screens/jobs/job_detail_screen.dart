import 'package:flutter/material.dart';
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
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) return false;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الدخول مطلوب'),
        content: const Text('يجب تسجيل الدخول للقيام بهذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()));
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
    return true;
  }

  Future<void> _toggleSave() async {
    if (_requireLogin()) return;
    try {
      if (_isSaved) {
        await SavedService.unsaveOffer(widget.offerId);
      } else {
        await SavedService.saveOffer(widget.offerId);
      }
      if (!mounted) return;
      setState(() => _isSaved = !_isSaved);
      showSnack(context, _isSaved ? 'تم حفظ العرض' : 'تم إلغاء الحفظ');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _apply() async {
    if (_requireLogin()) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isSeeker) {
      showSnack(context, 'الترشّح متاح لحسابات الباحثين عن عمل فقط', error: true);
      return;
    }

    final coverLetter = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CoverLetterSheet(),
    );
    if (coverLetter == null) return; // ألغى المستخدم

    try {
      await ApplicationService.apply(widget.offerId, coverLetter: coverLetter);
      if (!mounted) return;
      setState(() => _hasApplied = true);
      showSnack(context, 'تم إرسال طلبك بنجاح');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

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
        appBar: AppBar(title: const Text('تفاصيل الوظيفة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _offer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الوظيفة')),
        body: ErrorState(message: _error ?? 'العرض غير موجود', onRetry: _load),
      );
    }

    final o = _offer!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الوظيفة'),
        actions: [
          IconButton(
            onPressed: _share,
            icon: const Icon(Icons.share_rounded),
            tooltip: 'مشاركة',
          ),
          IconButton(
            onPressed: _toggleSave,
            icon: Icon(_isSaved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded),
            tooltip: _isSaved ? 'إلغاء الحفظ' : 'حفظ العرض',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ترويسة المؤسسة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CompanyAvatar(
                      company: o.company, sector: o.sector, size: 64),
                ),
                const SizedBox(height: 14),
                Text(
                  o.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: o.company == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CompanyDetailScreen(companyId: o.company!.id),
                            ),
                          ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          o.company?.name ?? '',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      if (o.company?.isVerified ?? false) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.verified_rounded,
                            size: 15, color: Colors.white),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 15, color: Colors.white70),
                    const SizedBox(width: 3),
                    Text(o.wilaya,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        Labels.contract(o.contractType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الراتب
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_rounded,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      const Text('الراتب: ',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Expanded(
                        child: Text(
                          o.salaryLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // معلومات سريعة
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (o.educationLevel != null)
                      _infoPill(Icons.school_rounded,
                          Labels.education(o.educationLevel)),
                    if (o.experienceLevel != null)
                      _infoPill(Icons.work_history_rounded,
                          Labels.experience(o.experienceLevel)),
                    _infoPill(Icons.category_rounded, Labels.sector(o.sector)),
                    if (o.expiresAt != null)
                      _infoPill(Icons.event_busy_rounded,
                          'ينتهي ${_formatDate(o.expiresAt!)}'),
                  ],
                ),
                const SizedBox(height: 22),

                const Text('وصف الوظيفة',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  o.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.8,
                    color: AppColors.textSecondary,
                  ),
                ),

                if (o.skills.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const Text('المهارات المطلوبة',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  ...o.skills.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_rounded,
                                size: 17, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],

                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: _report,
                    icon: const Icon(Icons.flag_outlined,
                        size: 17, color: AppColors.danger),
                    label: const Text(
                      'الإبلاغ عن هذا العرض',
                      style: TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),

      // زر «تقديم الطلب» الثابت
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: _hasApplied
            ? Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'تم إرسال طلبك لهذا العرض',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : ElevatedButton.icon(
                onPressed: _apply,
                icon: const Icon(Icons.send_rounded, size: 19),
                label: const Text('تقديم الطلب'),
              ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontSize: 12.5)),
          ],
        ),
      );

  static String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
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
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'تقديم الطلب',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'سترسل سيرتك الذاتية الرقمية مع هذا الطلب',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _ctrl,
                maxLines: 5,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText: 'رسالة تحفيزية (اختيارية)...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
                icon: const Icon(Icons.send_rounded, size: 19),
                label: const Text('إرسال الطلب'),
              ),
              const SizedBox(height: 8),
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

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 12,
          top: 8,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'سبب الإبلاغ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const Divider(height: 1),
            ...Labels.reportReasons.entries.map(
              (e) => ListTile(
                title: Text(e.value, style: const TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.chevron_left_rounded,
                    color: AppColors.textMuted),
                onTap: () => Navigator.pop(context, e.key),
              ),
            ),
          ],
        ),
      );
}
