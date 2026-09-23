import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import 'jobs_list_screen.dart';

/// وظائف حسب الولاية (3.2) — كل الولايات الـ58 مع عدد العروض
class WilayaJobsScreen extends StatefulWidget {
  const WilayaJobsScreen({super.key});

  @override
  State<WilayaJobsScreen> createState() => _WilayaJobsScreenState();
}

class _WilayaJobsScreenState extends State<WilayaJobsScreen> {
  final _searchCtrl = TextEditingController();
  Map<String, int> _counts = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await JobService.byWilaya();
      if (!mounted) return;
      setState(() {
        _counts = {
          for (final i in items) '${i['wilaya']}': (i['count'] ?? 0) as int
        };
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

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim();
    final wilayas = query.isEmpty
        ? Labels.wilayas
        : Labels.wilayas.where((w) => w.contains(query)).toList();

    return Scaffold(
      appBar: AppBar(
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          title: const Text('وظائف حسب الولاية')),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'ابحث عن ولاية...',
                prefixIcon: Icon(Icons.search_rounded),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : wilayas.isEmpty
                        ? const EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'لا توجد ولاية بهذا الاسم',
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 2.3,
                            ),
                            itemCount: wilayas.length,
                            itemBuilder: (_, i) {
                              final w = wilayas[i];
                              final count = _counts[w] ?? 0;
                              final code = Labels.wilayas.indexOf(w) + 1;

                              return InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        JobsListScreen(initialWilaya: w),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(9),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$code',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              w,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              count == 0
                                                  ? 'لا توجد عروض'
                                                  : '$count عرض',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: count == 0
                                                    ? AppColors.textMuted
                                                    : AppColors.success,
                                                fontWeight: count == 0
                                                    ? FontWeight.w400
                                                    : FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
