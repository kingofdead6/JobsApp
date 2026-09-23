import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/company_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import 'post_job_screen.dart';
import 'offer_applicants_screen.dart';

/// تسيير العروض: تعديل، إيقاف، تمديد، إعادة نشر، عرض الترشّحات (3.6)
class MyJobsScreen extends StatefulWidget {
  /// عند عرضها كتبويب داخل هيكل المؤسسة: بلا زر رجوع
  final bool embedded;
  const MyJobsScreen({super.key, this.embedded = false});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  List<JobOffer> _items = [];
  bool _loading = true;
  String? _error;
  String? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await JobService.mine(status: _filter);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _action(JobOffer offer, String action) async {
    int? days;
    if (action == 'extend') {
      days = await showDialog<int>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('تمديد مدّة العرض'),
          children: [15, 30, 60]
              .map((d) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, d),
                    child: Text('$d يومًا'),
                  ))
              .toList(),
        ),
      );
      if (days == null) return;
    }

    try {
      await JobService.changeState(offer.id, action, days: days);
      if (!mounted) return;
      showSnack(context, 'تم تحديث حالة العرض');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _delete(JobOffer offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العرض'),
        content: Text('هل تريد حذف عرض «${offer.title}» نهائيًا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(90, 44),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await JobService.remove(offer.id);
      if (!mounted) return;
      showSnack(context, 'تم حذف العرض');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  static Color _statusColor(String s) => switch (s) {
        'approved' => AppColors.success,
        'pending' => AppColors.warning,
        'rejected' => AppColors.danger,
        'paused' => AppColors.textSecondary,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: CompanyColors.gradient),
        ),
        title: const Text('عروضي'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostJobScreen()),
        ).then((_) => _load()),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('عرض جديد',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _chip('الكل', null),
                  const SizedBox(width: 8),
                  _chip('منشور', 'approved'),
                  const SizedBox(width: 8),
                  _chip('قيد المراجعة', 'pending'),
                  const SizedBox(width: 8),
                  _chip('مرفوض', 'rejected'),
                  const SizedBox(width: 8),
                  _chip('موقوف', 'paused'),
                  const SizedBox(width: 8),
                  _chip('منتهٍ', 'expired'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final selected = _filter == value;
    return InkWell(
      onTap: () {
        setState(() => _filter = value);
        _load();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);

    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.work_off_rounded,
        title: 'لا توجد عروض',
        subtitle: 'انشر عرضك الأول ليصل إلى المترشّحين',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final o = _items[i];
          final color = _statusColor(o.status);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          Labels.offer(o.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (o.status == 'rejected' && o.rejectionReason != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'سبب الرفض: ${o.rejectionReason}',
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _stat(Icons.visibility_rounded, '${o.viewsCount}'),
                      const SizedBox(width: 16),
                      _stat(Icons.people_rounded, '${o.applicationsCount}'),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          o.wilaya,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OfferApplicantsScreen(
                                offerId: o.id,
                                offerTitle: o.title,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.people_outline_rounded,
                              size: 17),
                          label: const Text('الترشّحات',
                              style: TextStyle(fontSize: 12.5)),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => PostJobScreen(editing: o)),
                          ).then((_) => _load()),
                          icon: const Icon(Icons.edit_outlined, size: 17),
                          label: const Text('تعديل',
                              style: TextStyle(fontSize: 12.5)),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        onSelected: (v) =>
                            v == 'delete' ? _delete(o) : _action(o, v),
                        itemBuilder: (_) => [
                          if (o.status == 'approved')
                            const PopupMenuItem(
                                value: 'pause', child: Text('إيقاف مؤقت')),
                          if (o.status == 'paused')
                            const PopupMenuItem(
                                value: 'resume', child: Text('إعادة تفعيل')),
                          const PopupMenuItem(
                              value: 'extend', child: Text('تمديد المدّة')),
                          if (o.status == 'expired' || o.status == 'rejected')
                            const PopupMenuItem(
                                value: 'republish', child: Text('إعادة نشر')),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('حذف',
                                style: TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _stat(IconData icon, String value) => Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      );
}
