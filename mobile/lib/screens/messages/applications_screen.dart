import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../company/my_jobs_screen.dart';
import 'chat_screen.dart';

/// طلبات التوظيف وحالتها (3.7)
/// الباحث يرى طلباته؛ المؤسسة تُوجَّه إلى عروضها لمتابعة الترشّحات.
class ApplicationsScreen extends StatefulWidget {
  final bool isCompany;
  const ApplicationsScreen({super.key, this.isCompany = false});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  List<ApplicationModel> _items = [];
  bool _loading = true;
  String? _error;
  String? _filter;

  @override
  void initState() {
    super.initState();
    if (!widget.isCompany) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ApplicationService.mine(status: _filter);
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

  static Color statusColor(String status) => switch (status) {
        'accepted' => AppColors.success,
        'rejected' => AppColors.danger,
        _ => AppColors.warning,
      };

  static IconData statusIcon(String status) => switch (status) {
        'accepted' => PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
        'rejected' => PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
        _ => PhosphorIcons.hourglassMedium(PhosphorIconsStyle.fill),
      };

  @override
  Widget build(BuildContext context) {
    // جانب المؤسسة: الترشّحات تُتابَع من داخل كل عرض
    if (widget.isCompany) {
      return EmptyState(
        icon: PhosphorIcons.folderOpen(PhosphorIconsStyle.fill),
        title: 'الترشّحات المستلمة',
        subtitle: 'تابع الترشّحات من صفحة كل عرض من عروضك',
        action: SizedBox(
          width: 200,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyJobsScreen()),
            ),
            child: const Text('عروضي'),
          ),
        ),
      );
    }

    return Column(
      children: [
        // تصفية بالحالة
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
      return EmptyState(
        icon: PhosphorIcons.clipboardText(PhosphorIconsStyle.regular),
        title: 'لا توجد طلبات',
        subtitle: 'ابحث عن عرض يناسبك وقدّم طلبك',
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
          final color = statusColor(a.status);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CompanyAvatar(
                        company: a.offer?.company,
                        sector: a.offer?.sector,
                        size: 42,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.offer?.title ?? 'عرض محذوف',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14.5, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              a.offer?.company?.name ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon(a.status), size: 13, color: color),
                            const SizedBox(width: 4),
                            Text(
                              Labels.appStatus(a.status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (a.statusNote != null && a.statusNote!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        a.statusNote!,
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'قُدّم ${timeAgo(a.createdAt)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              applicationId: a.id,
                              title: a.offer?.company?.name ?? 'المؤسسة',
                            ),
                          ),
                        ),
                        icon: Icon(PhosphorIcons.chatCircle(PhosphorIconsStyle.regular),
                            size: 16),
                        label: const Text('مراسلة',
                            style: TextStyle(fontSize: 12.5)),
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
}
