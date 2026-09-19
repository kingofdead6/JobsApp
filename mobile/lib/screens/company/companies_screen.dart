import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import 'company_detail_screen.dart';

/// دليل المؤسسات (3.8)
class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<CompanyModel> _items = [];
  bool _loading = true;
  String? _error;
  String? _sector;
  bool _verifiedOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await CompanyService.list(
        q: _searchCtrl.text.trim(),
        sector: _sector,
        verifiedOnly: _verifiedOnly,
      );
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

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الشركات')),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن مؤسسة...',
                    prefixIcon: Icon(Icons.search_rounded),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _sector,
                        isExpanded: true,
                        hint: const Text('كل القطاعات',
                            style: TextStyle(fontSize: 13)),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                              value: null, child: Text('كل القطاعات')),
                          ...Labels.sectors.entries.map((e) =>
                              DropdownMenuItem(
                                  value: e.key, child: Text(e.value))),
                        ],
                        onChanged: (v) {
                          setState(() => _sector = v);
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        setState(() => _verifiedOnly = !_verifiedOnly);
                        _load();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 13),
                        decoration: BoxDecoration(
                          color: _verifiedOnly
                              ? AppColors.info.withValues(alpha: 0.1)
                              : AppColors.surface,
                          border: Border.all(
                              color: _verifiedOnly
                                  ? AppColors.info
                                  : AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded,
                                size: 16,
                                color: _verifiedOnly
                                    ? AppColors.info
                                    : AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              'موثّقة',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: _verifiedOnly
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _verifiedOnly
                                    ? AppColors.info
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);

    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.business_outlined,
        title: 'لا توجد مؤسسات',
        subtitle: 'جرّب تغيير معايير البحث',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final c = _items[i];
          return Card(
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CompanyDetailScreen(companyId: c.id)),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CompanyAvatar(company: c, size: 52),
                    const SizedBox(width: 14),
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (c.isVerified) ...[
                                const SizedBox(width: 5),
                                const VerifiedBadge(size: 15),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Labels.sector(c.sector),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 13, color: AppColors.tileGreen),
                              const SizedBox(width: 2),
                              Text(
                                c.wilaya ?? '',
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 10),
                              if (c.activeOffers > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${c.activeOffers} عرض نشط',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left_rounded,
                        color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
