import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';

/// تعديل الملف الشخصي والسيرة الذاتية (3.5)
class EditProfileScreen extends StatefulWidget {
  final ProfileModel profile;
  final UserModel user;

  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _fullName = TextEditingController(text: widget.user.fullName);
  late final _email = TextEditingController(text: widget.user.email ?? '');
  late final _headline = TextEditingController(text: widget.profile.headline ?? '');
  late final _bio = TextEditingController(text: widget.profile.bio ?? '');
  late final _profession =
      TextEditingController(text: widget.profile.profession ?? '');
  late final _years = TextEditingController(
      text: '${widget.profile.yearsOfExperience}');

  late String? _wilaya = widget.user.wilaya;
  late String? _sector = widget.profile.sector;
  late String? _educationLevel = widget.profile.educationLevel;
  late List<String> _skills = [...widget.profile.skills];
  late List<dynamic> _languages = [...widget.profile.languages];

  bool _saving = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _headline.dispose();
    _bio.dispose();
    _profession.dispose();
    _years.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _saving = true);
    try {
      final (profile, user) = await ProfileService.update({
        'fullName': _fullName.text.trim(),
        'email': _email.text.trim(),
        'wilaya': _wilaya,
        'headline': _headline.text.trim(),
        'bio': _bio.text.trim(),
        'profession': _profession.text.trim(),
        'sector': _sector,
        'educationLevel': _educationLevel,
        'yearsOfExperience': int.tryParse(_years.text.trim()) ?? 0,
        'skills': _skills,
        'languages': _languages,
      });

      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      auth.setProfile(profile);
      auth.setUser(user);
      showSnack(context, 'تم حفظ التعديلات');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addSkill() async {
    final skill = await _promptText('إضافة مهارة', 'مثال: العمل الجماعي');
    if (skill != null && skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() => _skills.add(skill));
    }
  }

  Future<void> _addLanguage() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const _LanguageDialog(),
    );
    if (result != null) setState(() => _languages.add(result));
  }

  Future<void> _addExperience() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _ExperienceDialog(),
    );
    if (result == null) return;

    try {
      await ProfileService.addExperience(result);
      if (mounted) showSnack(context, 'تمت إضافة الخبرة');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _addEducation() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _EducationDialog(),
    );
    if (result == null) return;

    try {
      await ProfileService.addEducation(result);
      if (mounted) showSnack(context, 'تمت إضافة الشهادة');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<String?> _promptText(String title, String hint) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white),
                  )
                : const Text('حفظ',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('الاسم الكامل *'),
            TextFormField(
              controller: _fullName,
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'الاسم يجب ألّا يقلّ عن 3 أحرف'
                  : null,
            ),
            const SizedBox(height: 16),

            _label('المسمّى المهني'),
            TextFormField(
              controller: _headline,
              decoration: const InputDecoration(
                  hintText: 'مثال: تقني سامي في الإعلام الآلي'),
            ),
            const SizedBox(height: 16),

            _label('نبذة مختصرة'),
            TextFormField(
              controller: _bio,
              maxLines: 4,
              maxLength: 1000,
              decoration:
                  const InputDecoration(hintText: 'عرّف بنفسك وبخبرتك...'),
            ),
            const SizedBox(height: 8),

            _label('البريد الإلكتروني'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null;
                return RegExp(r'^\S+@\S+\.\S+$').hasMatch(t)
                    ? null
                    : 'بريد إلكتروني غير صالح';
              },
            ),
            const SizedBox(height: 16),

            _label('الولاية'),
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

            _label('المهنة'),
            TextFormField(
              controller: _profession,
              decoration: const InputDecoration(hintText: 'مثال: كهربائي'),
            ),
            const SizedBox(height: 16),

            _label('القطاع'),
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

            _label('المستوى الدراسي'),
            DropdownButtonFormField<String>(
              initialValue: _educationLevel,
              isExpanded: true,
              hint: const Text('اختر المستوى'),
              items: Labels.educationLevels.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _educationLevel = v),
            ),
            const SizedBox(height: 16),

            _label('سنوات الخبرة'),
            TextFormField(
              controller: _years,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 0 || n > 60) return 'أدخل عددًا بين 0 و60';
                return null;
              },
            ),
            const SizedBox(height: 22),

            // المهارات
            _sectionHeader('المهارات', onAdd: _addSkill),
            const SizedBox(height: 10),
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
                          deleteIcon: const Icon(Icons.close_rounded, size: 15),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 22),

            // اللغات
            _sectionHeader('اللغات', onAdd: _addLanguage),
            const SizedBox(height: 10),
            if (_languages.isEmpty)
              const Text('لم تُضف أي لغة',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted))
            else
              Column(
                children: _languages.map((l) {
                  final map = l as Map;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text('${map['name']}',
                        style: const TextStyle(fontSize: 13.5)),
                    subtitle: Text(
                      Labels.languageLevels['${map['level']}'] ?? '',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 19, color: AppColors.danger),
                      onPressed: () => setState(() => _languages.remove(l)),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 22),

            // الخبرات والشهادات تُحفظ مباشرة عبر الـ API
            OutlinedButton.icon(
              onPressed: _addExperience,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة خبرة مهنية'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _addEducation,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة شهادة'),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: const Text('حفظ التعديلات'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
      );

  Widget _sectionHeader(String title, {required VoidCallback onAdd}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('إضافة'),
          ),
        ],
      );
}

class _LanguageDialog extends StatefulWidget {
  const _LanguageDialog();

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  final _name = TextEditingController();
  String _level = 'good';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('إضافة لغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'مثال: الفرنسية'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _level,
              isExpanded: true,
              items: Labels.languageLevels.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _level = v ?? 'good'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = _name.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context, {'name': name, 'level': _level});
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
            child: const Text('إضافة'),
          ),
        ],
      );
}

class _ExperienceDialog extends StatefulWidget {
  const _ExperienceDialog();

  @override
  State<_ExperienceDialog> createState() => _ExperienceDialogState();
}

class _ExperienceDialogState extends State<_ExperienceDialog> {
  final _title = TextEditingController();
  final _company = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _current = false;

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => isStart ? _start = picked : _end = picked);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('إضافة خبرة مهنية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'المسمّى الوظيفي *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _company,
                decoration: const InputDecoration(labelText: 'المؤسسة'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_start == null
                    ? 'تاريخ البداية *'
                    : '${_start!.month}/${_start!.year}'),
                trailing: const Icon(Icons.calendar_today_rounded, size: 18),
                onTap: () => _pickDate(isStart: true),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _current,
                onChanged: (v) => setState(() => _current = v ?? false),
                title: const Text('أعمل هنا حاليًا',
                    style: TextStyle(fontSize: 13.5)),
              ),
              if (!_current)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_end == null
                      ? 'تاريخ النهاية'
                      : '${_end!.month}/${_end!.year}'),
                  trailing: const Icon(Icons.calendar_today_rounded, size: 18),
                  onTap: () => _pickDate(isStart: false),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_title.text.trim().isEmpty || _start == null) {
                showSnack(context, 'المسمّى وتاريخ البداية مطلوبان', error: true);
                return;
              }
              Navigator.pop(context, {
                'title': _title.text.trim(),
                'company': _company.text.trim(),
                'startDate': _start!.toIso8601String(),
                if (!_current && _end != null) 'endDate': _end!.toIso8601String(),
                'current': _current,
              });
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
            child: const Text('إضافة'),
          ),
        ],
      );
}

class _EducationDialog extends StatefulWidget {
  const _EducationDialog();

  @override
  State<_EducationDialog> createState() => _EducationDialogState();
}

class _EducationDialogState extends State<_EducationDialog> {
  final _degree = TextEditingController();
  final _institution = TextEditingController();
  final _year = TextEditingController();
  String? _level;

  @override
  void dispose() {
    _degree.dispose();
    _institution.dispose();
    _year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('إضافة شهادة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _degree,
                decoration: const InputDecoration(labelText: 'اسم الشهادة *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _institution,
                decoration: const InputDecoration(labelText: 'المؤسسة التعليمية'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _level,
                isExpanded: true,
                hint: const Text('المستوى'),
                items: Labels.educationLevels.entries
                    .map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _level = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _year,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'سنة التخرّج'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_degree.text.trim().isEmpty) {
                showSnack(context, 'اسم الشهادة مطلوب', error: true);
                return;
              }
              Navigator.pop(context, {
                'degree': _degree.text.trim(),
                'institution': _institution.text.trim(),
                if (_level != null) 'level': _level,
                if (int.tryParse(_year.text.trim()) != null)
                  'year': int.parse(_year.text.trim()),
              });
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
            child: const Text('إضافة'),
          ),
        ],
      );
}
