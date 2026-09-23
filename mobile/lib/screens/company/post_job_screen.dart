import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';

/// معالج نشر العرض من ثلاث خطوات (3.6):
/// معلومات الوظيفة ← تفاصيل إضافية ← المراجعة والنشر
class PostJobScreen extends StatefulWidget {
  final JobOffer? editing;
  const PostJobScreen({super.key, this.editing});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  int _step = 0;

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  // الخطوة 1 — الحقول الإجبارية
  late final _title = TextEditingController(text: widget.editing?.title ?? '');
  late final _profession =
      TextEditingController(text: widget.editing?.profession ?? '');
  late String? _sector = widget.editing?.sector;
  late String? _wilaya = widget.editing?.wilaya;
  late String _contractType = widget.editing?.contractType ?? 'full_time';
  late final _salaryMin = TextEditingController(
      text: widget.editing?.salaryMin?.toString() ?? '');
  late final _salaryMax = TextEditingController(
      text: widget.editing?.salaryMax?.toString() ?? '');

  // الخطوة 2 — تفاصيل إضافية
  late final _description =
      TextEditingController(text: widget.editing?.description ?? '');
  late final List<String> _skills = [...(widget.editing?.skills ?? [])];
  late String? _educationLevel = widget.editing?.educationLevel;
  late String? _experienceLevel = widget.editing?.experienceLevel;
  final _positions = TextEditingController(text: '1');

  bool _submitting = false;

  bool get _isEditing => widget.editing != null;

  @override
  void dispose() {
    _title.dispose();
    _profession.dispose();
    _salaryMin.dispose();
    _salaryMax.dispose();
    _description.dispose();
    _positions.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      if (!_step1Key.currentState!.validate()) return;
      if (_sector == null) {
        showSnack(context, 'اختر المهنة / القطاع', error: true);
        return;
      }
      if (_wilaya == null) {
        showSnack(context, 'اختر الولاية', error: true);
        return;
      }
      // التحقّق من ترتيب الراتب قبل الانتقال
      final min = int.tryParse(_salaryMin.text.trim());
      final max = int.tryParse(_salaryMax.text.trim());
      if (min != null && max != null && min > max) {
        showSnack(context, 'الراتب الأدنى لا يمكن أن يتجاوز الأقصى', error: true);
        return;
      }
    } else if (_step == 1) {
      if (!_step2Key.currentState!.validate()) return;
    }

    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final body = {
      'title': _title.text.trim(),
      'profession': _profession.text.trim(),
      'sector': _sector,
      'wilaya': _wilaya,
      'contractType': _contractType,
      'description': _description.text.trim(),
      'skills': _skills,
      if (_educationLevel != null) 'educationLevel': _educationLevel,
      if (_experienceLevel != null) 'experienceLevel': _experienceLevel,
      'positions': int.tryParse(_positions.text.trim()) ?? 1,
      if (int.tryParse(_salaryMin.text.trim()) != null)
        'salaryMin': int.parse(_salaryMin.text.trim()),
      if (int.tryParse(_salaryMax.text.trim()) != null)
        'salaryMax': int.parse(_salaryMax.text.trim()),
    };

    try {
      if (_isEditing) {
        await JobService.update(widget.editing!.id, body);
      } else {
        await JobService.create(body);
      }
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
              color: AppColors.success, size: 48),
          title: const Text('تم إرسال العرض', textAlign: TextAlign.center),
          content: const Text(
            'سيظهر عرضك في نتائج البحث بعد مصادقة المشرف عليه.',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _addSkill() async {
    final ctrl = TextEditingController();
    final skill = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مهارة مطلوبة'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'مثال: رخصة سياقة صنف B'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (skill != null && skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() => _skills.add(skill));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'تعديل العرض' : 'نشر عرض عمل'),
          leading: IconButton(
            icon: Icon(PhosphorIcons.arrowRight(PhosphorIconsStyle.bold)),
            onPressed: _back,
          ),
        ),
        body: Column(
          children: [
            _stepper(),
            const Divider(height: 1),
            Expanded(
              child: IndexedStack(
                index: _step,
                children: [_step1(), _step2(), _step3()],
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  /// مؤشّر الخطوات الثلاث (يُقرأ من اليمين: 1 ← 2 ← 3)
  Widget _stepper() => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        child: Row(
          children: List.generate(5, (i) {
            if (i.isOdd) {
              final done = _step >= (i ~/ 2) + 1;
              return Expanded(
                child: Container(
                  height: 2,
                  color: done ? AppColors.primary : AppColors.border,
                ),
              );
            }

            final index = i ~/ 2;
            final active = _step >= index;
            const titles = ['معلومات الوظيفة', 'تفاصيل إضافية', 'المراجعة'];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                      width: 1.6,
                    ),
                  ),
                  child: Center(
                    child: _step > index
                        ? Icon(PhosphorIcons.check(PhosphorIconsStyle.bold),
                            size: 16, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color:
                                  active ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 74,
                  child: Text(
                    titles[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color:
                          active ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      );

  Widget _step1() => Form(
        key: _step1Key,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('عنوان الوظيفة *'),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(hintText: 'مثال: محاسب'),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'عنوان الوظيفة مطلوب'
                  : null,
            ),
            const SizedBox(height: 16),

            _label('المهنة *'),
            TextFormField(
              controller: _profession,
              decoration: const InputDecoration(hintText: 'مثال: محاسب معتمد'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'المهنة مطلوبة' : null,
            ),
            const SizedBox(height: 16),

            _label('القطاع *'),
            DropdownButtonFormField<String>(
              initialValue: _sector,
              isExpanded: true,
              hint: const Text('اختر القطاع'),
              items: Labels.sectors.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _sector = v),
            ),
            const SizedBox(height: 16),

            _label('الولاية *'),
            DropdownButtonFormField<String>(
              initialValue: _wilaya,
              isExpanded: true,
              hint: const Text('اختر الولاية'),
              items: Labels.wilayas
                  .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                  .toList(),
              onChanged: (v) => setState(() => _wilaya = v),
            ),
            const SizedBox(height: 16),

            _label('نوع العقد *'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Labels.contractTypes.entries.map((e) {
                final selected = _contractType == e.key;
                return InkWell(
                  onTap: () => setState(() => _contractType = e.key),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _label('الراتب (اختياري)'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _salaryMin,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'من',
                      suffixText: 'دج',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _salaryMax,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'إلى',
                      suffixText: 'دج',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      );

  Widget _step2() => Form(
        key: _step2Key,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('وصف الوظيفة *'),
            TextFormField(
              controller: _description,
              maxLines: 7,
              maxLength: 5000,
              decoration: const InputDecoration(
                hintText: 'اشرح المهام، شروط العمل، ومتطلّبات المنصب...',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().length < 20)
                  ? 'الوصف مطلوب (20 محرفًا على الأقل)'
                  : null,
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _label('المهارات المطلوبة'),
                TextButton.icon(
                  onPressed: _addSkill,
                  icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), size: 18),
                  label: const Text('إضافة'),
                ),
              ],
            ),
            if (_skills.isEmpty)
              const Text('لم تُضف أي مهارة',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skills
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          onDeleted: () => setState(() => _skills.remove(s)),
                          deleteIcon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold), size: 15),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 20),

            _label('المستوى الدراسي المطلوب'),
            DropdownButtonFormField<String>(
              initialValue: _educationLevel,
              isExpanded: true,
              hint: const Text('غير محدّد'),
              items: [
                const DropdownMenuItem<String>(
                    value: null, child: Text('غير محدّد')),
                ...Labels.educationLevels.entries.map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
              ],
              onChanged: (v) => setState(() => _educationLevel = v),
            ),
            const SizedBox(height: 16),

            _label('مستوى الخبرة المطلوب'),
            DropdownButtonFormField<String>(
              initialValue: _experienceLevel,
              isExpanded: true,
              hint: const Text('غير محدّد'),
              items: [
                const DropdownMenuItem<String>(
                    value: null, child: Text('غير محدّد')),
                ...Labels.experienceLevels.entries.map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
              ],
              onChanged: (v) => setState(() => _experienceLevel = v),
            ),
            const SizedBox(height: 16),

            _label('عدد المناصب'),
            TextFormField(
              controller: _positions,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 1) return 'أدخل عددًا صحيحًا (1 أو أكثر)';
                return null;
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      );

  /// الخطوة 3 — مراجعة ما سيُنشر قبل الإرسال
  Widget _step3() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.info(PhosphorIconsStyle.bold),
                    color: AppColors.info, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'سيراجع المشرف عرضك قبل نشره، حمايةً للمستخدمين من الإعلانات الوهمية.',
                    style: TextStyle(fontSize: 12.5, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title.text.trim(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  _reviewRow('المهنة', _profession.text.trim()),
                  _reviewRow('القطاع', Labels.sector(_sector)),
                  _reviewRow('الولاية', _wilaya ?? '-'),
                  _reviewRow('نوع العقد', Labels.contract(_contractType)),
                  _reviewRow('الراتب', _salaryText()),
                  _reviewRow(
                      'المستوى الدراسي',
                      _educationLevel == null
                          ? 'غير محدّد'
                          : Labels.education(_educationLevel)),
                  _reviewRow(
                      'مستوى الخبرة',
                      _experienceLevel == null
                          ? 'غير محدّد'
                          : Labels.experience(_experienceLevel)),
                  _reviewRow('عدد المناصب', _positions.text.trim()),
                  const Divider(height: 24),
                  const Text('الوصف',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    _description.text.trim(),
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.7,
                        color: AppColors.textSecondary),
                  ),
                  if (_skills.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('المهارات المطلوبة',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _skills
                          .map((s) => Chip(
                                label: Text(s,
                                    style: const TextStyle(fontSize: 11.5)),
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.07),
                                side: BorderSide.none,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      );

  String _salaryText() {
    final min = _salaryMin.text.trim();
    final max = _salaryMax.text.trim();
    if (min.isEmpty && max.isEmpty) return 'غير محدّد';
    if (min.isNotEmpty && max.isNotEmpty) return '$min - $max دج';
    return min.isNotEmpty ? 'ابتداءً من $min دج' : 'حتى $max دج';
  }

  Widget _reviewRow(String label, String value) => Padding(
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

  Widget _bottomBar() => Container(
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
        child: Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : _back,
                  child: const Text('السابق'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: _step > 0 ? 1 : 1,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : (_step == 2 ? _submit : _next),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: Colors.white),
                      )
                    : Icon(
                        _step == 2
                            ? PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill)
                            : PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                        size: 19,
                      ),
                label: Text(_step == 2
                    ? (_isEditing ? 'حفظ التعديلات' : 'نشر العرض')
                    : 'التالي'),
              ),
            ),
          ],
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
      );
}
