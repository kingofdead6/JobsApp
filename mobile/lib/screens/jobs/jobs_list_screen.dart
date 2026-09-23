import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import 'job_detail_screen.dart';
import 'filters_sheet.dart';

/// قائمة عروض العمل مع البحث والتصفية (3.3)
class JobsListScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialWilaya;
  final String? companyId;
  final String? companyName;
  final bool featuredOnly;

  const JobsListScreen({
    super.key,
    this.initialQuery,
    this.initialWilaya,
    this.companyId,
    this.companyName,
    this.featuredOnly = false,
  });

  @override
  State<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends State<JobsListScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  final List<JobOffer> _items = [];
  JobFilters _filters = const JobFilters();

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _pages = 1;

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.initialQuery ?? '';
    _filters = JobFilters(wilaya: widget.initialWilaya);
    _scrollCtrl.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 300 &&
        !_loadingMore &&
        _page < _pages) {
      _loadMore();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    }

    try {
      final (items, pages) = await JobService.search(
        q: _searchCtrl.text.trim(),
        wilaya: _filters.wilaya,
        sector: _filters.sector,
        contractType: _filters.contractType,
        salaryMin: _filters.salaryMin,
        educationLevel: _filters.educationLevel,
        experienceLevel: _filters.experienceLevel,
        postedWithin: _filters.postedWithin,
        companyId: widget.companyId,
        sort: _filters.sort,
        page: 1,
      );

      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(widget.featuredOnly
              ? items.where((o) => o.featured)
              : items);
        _pages = pages;
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

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final (items, pages) = await JobService.search(
        q: _searchCtrl.text.trim(),
        wilaya: _filters.wilaya,
        sector: _filters.sector,
        contractType: _filters.contractType,
        salaryMin: _filters.salaryMin,
        educationLevel: _filters.educationLevel,
        experienceLevel: _filters.experienceLevel,
        postedWithin: _filters.postedWithin,
        companyId: widget.companyId,
        sort: _filters.sort,
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _page++;
        _pages = pages;
        _items.addAll(widget.featuredOnly
            ? items.where((o) => o.featured)
            : items);
      });
    } on ApiException catch (_) {
      // تجاهل خطأ تحميل الصفحة التالية
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _load(reset: true));
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<JobFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FiltersSheet(initial: _filters),
    );
    if (result != null) {
      setState(() => _filters = result);
      _load(reset: true);
    }
  }

  Future<void> _toggleSave(JobOffer offer) async {
    final index = _items.indexWhere((o) => o.id == offer.id);
    try {
      if (offer.isSaved) {
        await SavedService.unsaveOffer(offer.id);
      } else {
        await SavedService.saveOffer(offer.id);
      }
      if (!mounted) return;
      // نبني نسخة محدّثة لأن الحقول نهائية
      setState(() {
        _items[index] = JobOffer(
          id: offer.id,
          title: offer.title,
          profession: offer.profession,
          sector: offer.sector,
          wilaya: offer.wilaya,
          contractType: offer.contractType,
          description: offer.description,
          salaryMin: offer.salaryMin,
          salaryMax: offer.salaryMax,
          skills: offer.skills,
          educationLevel: offer.educationLevel,
          experienceLevel: offer.experienceLevel,
          status: offer.status,
          featured: offer.featured,
          publishedAt: offer.publishedAt,
          expiresAt: offer.expiresAt,
          viewsCount: offer.viewsCount,
          applicationsCount: offer.applicationsCount,
          company: offer.company,
          isSaved: !offer.isSaved,
        );
      });
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _filters.activeCount;

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),        title: Text(widget.companyName ??
            (widget.featuredOnly ? 'العروض المميّزة' : 'عروض العمل')),
      ),
      body: Column(
        children: [
          // شريط البحث والتصفية
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(reset: true),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن وظيفة...',
                    prefixIcon: Icon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold)),
                    suffixIcon: _searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold), size: 20),
                            onPressed: () {
                              _searchCtrl.clear();
                              _load(reset: true);
                            },
                          ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _filterChip(
                        label: activeCount > 0 ? 'تصفية ($activeCount)' : 'تصفية',
                        icon: PhosphorIcons.slidersHorizontal(PhosphorIconsStyle.bold),
                        active: activeCount > 0,
                        onTap: _openFilters,
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        label: _filters.wilaya ?? 'الولاية',
                        icon: PhosphorIcons.mapPin(PhosphorIconsStyle.regular),
                        active: _filters.wilaya != null,
                        onTap: _openFilters,
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        label: _filters.sector != null
                            ? Labels.sector(_filters.sector)
                            : 'المهنة',
                        icon: PhosphorIcons.briefcase(PhosphorIconsStyle.regular),
                        active: _filters.sector != null,
                        onTap: _openFilters,
                      ),
                      const SizedBox(width: 8),
                      _filterChip(
                        label: _filters.contractType != null
                            ? Labels.contract(_filters.contractType)
                            : 'نوع العقد',
                        icon: PhosphorIcons.clock(PhosphorIconsStyle.bold),
                        active: _filters.contractType != null,
                        onTap: _openFilters,
                      ),
                    ],
                  ),
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
    if (_loading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const JobCardSkeleton(),
      );
    }

    if (_error != null) {
      return ErrorState(message: _error!, onRetry: () => _load(reset: true));
    }

    if (_items.isEmpty) {
      return EmptyState(
        icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.duotone),
        title: 'لا توجد نتائج',
        subtitle: 'جرّب تغيير كلمات البحث أو معايير التصفية',
        action: _filters.activeCount > 0
            ? SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _filters = const JobFilters());
                    _load(reset: true);
                  },
                  child: const Text('إزالة عوامل التصفية'),
                ),
              )
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final offer = _items[i];
          return JobCard(
            offer: offer,
            index: i,
            showSaveButton: true,
            onSaveToggle: () => _toggleSave(offer),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => JobDetailScreen(offerId: offer.id)),
            ).then((_) => _load(reset: true)),
          );
        },
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surface,
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 15,
                  color: active ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
}
