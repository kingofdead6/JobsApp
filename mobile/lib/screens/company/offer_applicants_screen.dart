import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../messages/chat_screen.dart';

/// الترشّحات المستلمة على عرض معيّن (3.6)
class OfferApplicantsScreen extends StatefulWidget {
  final String offerId;
  final String offerTitle;

  const OfferApplicantsScreen({
    super.key,
    required this.offerId,
    required this.offerTitle,
  });

  @override
  State<OfferApplicantsScreen> createState() => _OfferApplicantsScreenState();
}

class _OfferApplicantsScreenState extends State<OfferApplicantsScreen> {
  List<ApplicationModel> _items = [];
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
      final items =
          await ApplicationService.forOffer(widget.offerId, status: _filter);
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

  Future<void> _decide(ApplicationModel a, String status) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'accepted' ? 'قبول الترشّح' : 'رفض الترشّح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status == 'accepted'
                  ? 'سيُعلَم المترشّح بقبول طلبه.'
                  : 'سيُعلَم المترشّح برفض طلبه.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'ملاحظة للمترشّح (اختيارية)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  status == 'accepted' ? AppColors.success : AppColors.danger,
              minimumSize: const Size(90, 44),
            ),
            child: Text(status == 'accepted' ? 'قبول' : 'رفض'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApplicationService.setStatus(a.id, status,
          note: noteCtrl.text.trim());
      if (!mounted) return;
      showSnack(context, 'تم تحديث حالة الطلب');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  void _showCv(ApplicationModel a) {
    final cv = a.cvSnapshot ?? {};

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
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
                '${cv['fullName'] ?? a.applicant?.fullName ?? ''}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              if (cv['headline'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${cv['headline']}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 20),

              _cvRow('الهاتف', '${cv['phone'] ?? '-'}'),
              _cvRow('البريد', '${cv['email'] ?? '-'}'),
              _cvRow('الولاية', '${cv['wilaya'] ?? '-'}'),
              _cvRow('المهنة', '${cv['profession'] ?? '-'}'),
              _cvRow('المستوى الدراسي',
                  Labels.education('${cv['educationLevel']}')),
              _cvRow('سنوات الخبرة', '${cv['yearsOfExperience'] ?? 0}'),

              if (a.coverLetter != null && a.coverLetter!.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text('الرسالة التحفيزية',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(a.coverLetter!,
                      style: const TextStyle(fontSize: 13, height: 1.7)),
                ),
              ],

              if ((cv['skills'] as List?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 18),
                const Text('المهارات',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (cv['skills'] as List)
                      .map((s) => Chip(
                            label: Text('$s',
                                style: const TextStyle(fontSize: 11.5)),
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.07),
                            side: BorderSide.none,
                          ))
                      .toList(),
                ),
              ],

              if ((cv['experiences'] as List?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 18),
                const Text('الخبرات المهنية',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...(cv['experiences'] as List).map((e) {
                  final m = e as Map;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(PhosphorIcons.briefcase(PhosphorIconsStyle.fill),
                        size: 18, color: AppColors.primary),
                    title: Text('${m['title'] ?? ''}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: Text('${m['company'] ?? ''}',
                        style: const TextStyle(fontSize: 11.5)),
                  );
                }),
              ],

              if (cv['cvFile'] != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    final url = ApiClient.fileUrl('${cv['cvFile']}');
                    if (url != null) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: Icon(PhosphorIcons.filePdf(PhosphorIconsStyle.fill), size: 19),
                  label: const Text('فتح ملف السيرة الذاتية'),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cvRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),        title: Text(widget.offerTitle,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _chip('الكل', null),
                const SizedBox(width: 8),
                _chip('قيد الدراسة', 'pending'),
                const SizedBox(width: 8),
                _chip('مقبول', 'accepted'),
                const SizedBox(width: 8),
                _chip('مرفوض', 'rejected'),
              ],
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
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
      return EmptyState(
        icon: PhosphorIcons.users(PhosphorIconsStyle.regular),
        title: 'لا توجد ترشّحات',
        subtitle: 'لم يترشّح أحد لهذا العرض بعد',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final a = _items[i];
          final pending = a.status == 'pending';

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: a.applicant?.avatarUrl != null
                            ? NetworkImage(a.applicant!.avatarUrl!)
                            : null,
                        child: a.applicant?.avatarUrl == null
                            ? Icon(PhosphorIcons.user(PhosphorIconsStyle.fill),
                                color: AppColors.primary, size: 22)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    a.applicant?.fullName ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (!a.viewedByCompany)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.info,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'جديد',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${a.applicant?.wilaya ?? ''} · ${timeAgo(a.createdAt)}',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: (a.status == 'accepted'
                                  ? AppColors.success
                                  : a.status == 'rejected'
                                      ? AppColors.danger
                                      : AppColors.warning)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          Labels.appStatus(a.status),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: a.status == 'accepted'
                                ? AppColors.success
                                : a.status == 'rejected'
                                    ? AppColors.danger
                                    : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _showCv(a),
                          icon: Icon(PhosphorIcons.fileText(PhosphorIconsStyle.regular), size: 17),
                          label: const Text('السيرة',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                applicationId: a.id,
                                title: a.applicant?.fullName ?? 'المترشّح',
                                otherUserId: a.applicant?.id,
                              ),
                            ),
                          ),
                          icon: Icon(PhosphorIcons.chatCircle(PhosphorIconsStyle.regular),
                              size: 17),
                          label: const Text('مراسلة',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      if (pending) ...[
                        IconButton(
                          onPressed: () => _decide(a, 'accepted'),
                          icon: Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                              color: AppColors.success),
                          tooltip: 'قبول',
                        ),
                        IconButton(
                          onPressed: () => _decide(a, 'rejected'),
                          icon: Icon(PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
                              color: AppColors.danger),
                          tooltip: 'رفض',
                        ),
                      ],
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
}
