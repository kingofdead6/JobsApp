import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../jobs/job_detail_screen.dart';
import '../jobs/jobs_list_screen.dart';

/// العروض المحفوظة وعمليات البحث المحفوظة مع التنبيهات (3.3 / 3.4)
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<JobOffer> _offers = [];
  List<Map<String, dynamic>> _searches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final offers = await SavedService.offers();
      final searches = await SavedService.searches();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _searches = searches;
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

  Future<void> _unsave(JobOffer o) async {
    try {
      await SavedService.unsaveOffer(o.id);
      if (!mounted) return;
      setState(() => _offers.removeWhere((x) => x.id == o.id));
      showSnack(context, 'تم إلغاء الحفظ');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _toggleAlert(Map<String, dynamic> s, bool value) async {
    try {
      await SavedService.toggleAlert('${s['_id']}', value);
      if (!mounted) return;
      setState(() => s['alertEnabled'] = value);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _deleteSearch(Map<String, dynamic> s) async {
    try {
      await SavedService.deleteSearch('${s['_id']}');
      if (!mounted) return;
      setState(() => _searches.remove(s));
      showSnack(context, 'تم حذف البحث المحفوظ');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),          title: const Text('المحفوظات'),
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: [
              Tab(text: 'العروض المحفوظة'),
              Tab(text: 'عمليات البحث'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : TabBarView(
                    children: [_offersTab(), _searchesTab()],
                  ),
      ),
    );
  }

  Widget _offersTab() {
    if (_offers.isEmpty) {
      return const EmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'لا توجد عروض محفوظة',
        subtitle: 'احفظ العروض التي تهمّك للعودة إليها لاحقًا',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _offers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final o = _offers[i];
          return Dismissible(
            key: ValueKey(o.id),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.bookmark_remove_rounded,
                  color: Colors.white),
            ),
            onDismissed: (_) => _unsave(o),
            child: JobCard(
              offer: o,
              index: i,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => JobDetailScreen(offerId: o.id)),
              ).then((_) => _load()),
            ),
          );
        },
      ),
    );
  }

  Widget _searchesTab() {
    if (_searches.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_active_outlined,
        title: 'لا توجد عمليات بحث محفوظة',
        subtitle: 'احفظ بحثك لتصلك تنبيهات عند ظهور عرض مطابق',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _searches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final s = _searches[i];
          final criteria = (s['criteria'] as Map?) ?? {};
          final alertOn = s['alertEnabled'] == true;
          final matches = (s['matchCount'] ?? 0) as int;

          // وصف مقروء لمعايير البحث
          final parts = <String>[
            if (criteria['q'] != null && '${criteria['q']}'.isNotEmpty)
              '${criteria['q']}',
            if (criteria['wilaya'] != null) '${criteria['wilaya']}',
            if (criteria['sector'] != null)
              Labels.sector('${criteria['sector']}'),
            if (criteria['contractType'] != null)
              Labels.contract('${criteria['contractType']}'),
          ];

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
                          '${s['label'] ?? 'بحث محفوظ'}',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (matches > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$matches نتيجة',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (parts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: parts
                          .map((p) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(p,
                                    style: const TextStyle(fontSize: 11.5)),
                              ))
                          .toList(),
                    ),
                  ],
                  const Divider(height: 22),
                  Row(
                    children: [
                      Icon(
                        alertOn
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        size: 18,
                        color: alertOn
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      const Text('تنبيهني بالعروض الجديدة',
                          style: TextStyle(fontSize: 12.5)),
                      const Spacer(),
                      Switch(
                        value: alertOn,
                        onChanged: (v) => _toggleAlert(s, v),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JobsListScreen(
                                initialQuery: criteria['q'] as String?,
                                initialWilaya: criteria['wilaya'] as String?,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.search_rounded, size: 17),
                          label: const Text('عرض النتائج',
                              style: TextStyle(fontSize: 12.5)),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _deleteSearch(s),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 17, color: AppColors.danger),
                        label: const Text('حذف',
                            style: TextStyle(
                                fontSize: 12.5, color: AppColors.danger)),
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
