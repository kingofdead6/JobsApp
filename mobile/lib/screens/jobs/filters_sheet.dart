import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';

/// معايير التصفية والترتيب (3.3)
class JobFilters {
  final String? wilaya;
  final String? sector;
  final String? contractType;
  final int? salaryMin;
  final String? educationLevel;
  final String? experienceLevel;
  final int? postedWithin;
  final String sort;

  const JobFilters({
    this.wilaya,
    this.sector,
    this.contractType,
    this.salaryMin,
    this.educationLevel,
    this.experienceLevel,
    this.postedWithin,
    this.sort = 'recent',
  });

  int get activeCount => [
        wilaya,
        sector,
        contractType,
        salaryMin,
        educationLevel,
        experienceLevel,
        postedWithin,
      ].where((e) => e != null).length;

  JobFilters copyWith({
    Object? wilaya = _sentinel,
    Object? sector = _sentinel,
    Object? contractType = _sentinel,
    Object? salaryMin = _sentinel,
    Object? educationLevel = _sentinel,
    Object? experienceLevel = _sentinel,
    Object? postedWithin = _sentinel,
    String? sort,
  }) =>
      JobFilters(
        wilaya: wilaya == _sentinel ? this.wilaya : wilaya as String?,
        sector: sector == _sentinel ? this.sector : sector as String?,
        contractType: contractType == _sentinel
            ? this.contractType
            : contractType as String?,
        salaryMin: salaryMin == _sentinel ? this.salaryMin : salaryMin as int?,
        educationLevel: educationLevel == _sentinel
            ? this.educationLevel
            : educationLevel as String?,
        experienceLevel: experienceLevel == _sentinel
            ? this.experienceLevel
            : experienceLevel as String?,
        postedWithin: postedWithin == _sentinel
            ? this.postedWithin
            : postedWithin as int?,
        sort: sort ?? this.sort,
      );

  static const _sentinel = Object();
}

class FiltersSheet extends StatefulWidget {
  final JobFilters initial;
  const FiltersSheet({super.key, required this.initial});

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  late JobFilters _f = widget.initial;

  static const _salaryOptions = [30000, 40000, 50000, 80000, 100000];
  static const _dateOptions = {1: 'آخر 24 ساعة', 7: 'آخر أسبوع', 30: 'آخر شهر'};
  static const _sortOptions = {
    'recent': 'الأحدث',
    'salary': 'الأعلى راتبًا',
    'relevance': 'الأكثر صلة',
  };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            // مقبض السحب
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'تصفية النتائج',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _f = const JobFilters()),
                    child: const Text('إزالة الكل'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _section('الترتيب'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sortOptions.entries
                        .map((e) => _chip(
                              label: e.value,
                              selected: _f.sort == e.key,
                              onTap: () =>
                                  setState(() => _f = _f.copyWith(sort: e.key)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _section('الولاية'),
                  _dropdown<String>(
                    value: _f.wilaya,
                    hint: 'كل الولايات',
                    items: Labels.wilayas,
                    labelOf: (w) => w,
                    onChanged: (v) =>
                        setState(() => _f = _f.copyWith(wilaya: v)),
                  ),
                  const SizedBox(height: 20),
                  _section('القطاع / المهنة'),
                  _dropdown<String>(
                    value: _f.sector,
                    hint: 'كل القطاعات',
                    items: Labels.sectors.keys.toList(),
                    labelOf: Labels.sector,
                    onChanged: (v) =>
                        setState(() => _f = _f.copyWith(sector: v)),
                  ),
                  const SizedBox(height: 20),
                  _section('نوع العقد'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: Labels.contractTypes.entries
                        .map((e) => _chip(
                              label: e.value,
                              selected: _f.contractType == e.key,
                              onTap: () => setState(() => _f = _f.copyWith(
                                  contractType:
                                      _f.contractType == e.key ? null : e.key)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _section('الراتب الأدنى'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _salaryOptions
                        .map((s) => _chip(
                              label: '${(s / 1000).round()} ألف دج+',
                              selected: _f.salaryMin == s,
                              onTap: () => setState(() => _f = _f.copyWith(
                                  salaryMin: _f.salaryMin == s ? null : s)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _section('تاريخ النشر'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dateOptions.entries
                        .map((e) => _chip(
                              label: e.value,
                              selected: _f.postedWithin == e.key,
                              onTap: () => setState(() => _f = _f.copyWith(
                                  postedWithin:
                                      _f.postedWithin == e.key ? null : e.key)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _section('المستوى الدراسي'),
                  _dropdown<String>(
                    value: _f.educationLevel,
                    hint: 'كل المستويات',
                    items: Labels.educationLevels.keys.toList(),
                    labelOf: Labels.education,
                    onChanged: (v) =>
                        setState(() => _f = _f.copyWith(educationLevel: v)),
                  ),
                  const SizedBox(height: 20),
                  _section('مستوى الخبرة'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: Labels.experienceLevels.entries
                        .map((e) => _chip(
                              label: e.value,
                              selected: _f.experienceLevel == e.key,
                              onTap: () => setState(() => _f = _f.copyWith(
                                  experienceLevel: _f.experienceLevel == e.key
                                      ? null
                                      : e.key)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // زر التطبيق
            Container(
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
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _f),
                child: Text(
                  _f.activeCount > 0
                      ? 'تطبيق (${_f.activeCount} عوامل)'
                      : 'عرض النتائج',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
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

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) =>
      DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        hint: Text(hint),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        items: [
          DropdownMenuItem<T>(value: null, child: Text(hint)),
          ...items.map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(labelOf(e), overflow: TextOverflow.ellipsis),
              )),
        ],
        onChanged: onChanged,
      );
}
