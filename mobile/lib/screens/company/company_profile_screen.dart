import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';

/// ملف المؤسسة: إنشاء، تعديل، طلب التوثيق (3.8)
class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _website = TextEditingController();
  final _contactPhone = TextEditingController();
  final _contactEmail = TextEditingController();
  final _register = TextEditingController();

  String? _sector;
  String? _wilaya;
  String? _employeesRange;

  CompanyModel? _company;
  Map<String, dynamic>? _stats;
  bool _loading = true;
  bool _saving = false;
  bool _isNew = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _website.dispose();
    _contactPhone.dispose();
    _contactEmail.dispose();
    _register.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final company = await CompanyService.mine();
      final stats = await CompanyService.stats();
      if (!mounted) return;
      setState(() {
        _company = company;
        _stats = stats;
        _fill(company);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      // 404 يعني أن المؤسسة لم تُنشئ ملفها بعد
      setState(() {
        _isNew = e.statusCode == 404;
        _loading = false;
      });
      if (!_isNew && mounted) showSnack(context, e.message, error: true);
    }
  }

  void _fill(CompanyModel c) {
    _name.text = c.name;
    _description.text = c.description ?? '';
    _website.text = c.website ?? '';
    _sector = c.sector;
    _wilaya = c.wilaya;
    _employeesRange = c.employeesRange;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sector == null || _wilaya == null) {
      showSnack(context, 'القطاع والولاية مطلوبان', error: true);
      return;
    }

    setState(() => _saving = true);
    final body = {
      'name': _name.text.trim(),
      'sector': _sector,
      'wilaya': _wilaya,
      'description': _description.text.trim(),
      'address': _address.text.trim(),
      'website': _website.text.trim(),
      if (_contactPhone.text.trim().isNotEmpty)
        'contactPhone': _contactPhone.text.trim(),
      if (_contactEmail.text.trim().isNotEmpty)
        'contactEmail': _contactEmail.text.trim(),
      if (_employeesRange != null) 'employeesRange': _employeesRange,
    };

    try {
      final company =
          _isNew ? await CompanyService.create(body) : await CompanyService.update(body);
      if (!mounted) return;
      setState(() {
        _company = company;
        _isNew = false;
      });
      context.read<AuthProvider>().setCompany(company);
      showSnack(context, 'تم حفظ ملف المؤسسة');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    try {
      final company = await CompanyService.uploadLogo(picked.path);
      if (!mounted) return;
      setState(() => _company = company);
      showSnack(context, 'تم تحديث الشعار');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('ملف المؤسسة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'إنشاء ملف المؤسسة' : 'ملف المؤسسة'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isNew)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.info(PhosphorIconsStyle.bold),
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'أنشئ ملف مؤسستك لتتمكّن من نشر عروض العمل.',
                        style: TextStyle(fontSize: 12.5, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

            if (!_isNew && _company != null) ...[
              Center(
                child: Stack(
                  children: [
                    CompanyAvatar(company: _company, size: 84),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: GestureDetector(
                        onTap: _pickLogo,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(PhosphorIcons.camera(PhosphorIconsStyle.fill),
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _verificationCard(),
              const SizedBox(height: 14),
              if (_stats != null) _statsCard(),
              const SizedBox(height: 20),
            ],

            _label('اسم المؤسسة *'),
            TextFormField(
              controller: _name,
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'اسم المؤسسة مطلوب'
                  : null,
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

            _label('نبذة عن المؤسسة'),
            TextFormField(
              controller: _description,
              maxLines: 4,
              maxLength: 2000,
            ),

            _label('العنوان'),
            TextFormField(controller: _address),
            const SizedBox(height: 16),

            _label('الموقع الإلكتروني'),
            TextFormField(
              controller: _website,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            _label('هاتف التواصل'),
            TextFormField(
              controller: _contactPhone,
              keyboardType: TextInputType.phone,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null;
                return RegExp(r'^0[5-7]\d{8}$').hasMatch(t)
                    ? null
                    : 'رقم هاتف غير صالح';
              },
            ),
            const SizedBox(height: 16),

            _label('بريد التواصل'),
            TextFormField(
              controller: _contactEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            _label('عدد العمال'),
            DropdownButtonFormField<String>(
              initialValue: _employeesRange,
              isExpanded: true,
              hint: const Text('اختر'),
              items: const ['1-10', '11-50', '51-200', '201-500', '500+']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _employeesRange = v),
            ),
            const SizedBox(height: 26),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : Text(_isNew ? 'إنشاء الملف' : 'حفظ التعديلات'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _verificationCard() {
    final status = _company!.verificationStatus;
    final (label, color, icon) = switch (status) {
      'verified' => ('مؤسسة موثّقة', AppColors.success, PhosphorIcons.sealCheck(PhosphorIconsStyle.fill)),
      'pending' => ('طلب التوثيق قيد المراجعة', AppColors.warning,
          PhosphorIcons.hourglassMedium(PhosphorIconsStyle.fill)),
      'rejected' => ('طلب التوثيق مرفوض', AppColors.danger, PhosphorIcons.xCircle(PhosphorIconsStyle.fill)),
      _ => ('غير موثّقة', AppColors.textMuted, PhosphorIcons.shieldWarning(PhosphorIconsStyle.fill)),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  const SizedBox(height: 2),
                  const Text(
                    'التوثيق يمنح مؤسستك ثقة أكبر لدى المترشّحين',
                    style: TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (status == 'unverified' || status == 'rejected')
              TextButton(
                onPressed: _requestVerification,
                child: const Text('توثيق'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestVerification() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('طلب التوثيق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'أدخل رقم السجل التجاري لمؤسستك. سيراجع المشرف الطلب.',
              style: TextStyle(fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _register,
              decoration: const InputDecoration(
                labelText: 'رقم السجل التجاري',
                hintText: '16/00-1234567',
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
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 44)),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );

    if (ok != true || _register.text.trim().isEmpty) return;

    try {
      // الطلب يُرسل كـ multipart؛ هنا نكتفي برقم السجل دون وثيقة
      await ApiClient.instance.post('/companies/me/verification', {
        'commercialRegister': _register.text.trim(),
      });
      if (!mounted) return;
      showSnack(context, 'تم إرسال طلب التوثيق');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Widget _statsCard() {
    final offers = (_stats!['offersByStatus'] as Map?) ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('${offers['approved'] ?? 0}', 'عرض منشور'),
            _stat('${_stats!['totalViews'] ?? 0}', 'مشاهدة'),
            _stat('${_stats!['totalApplications'] ?? 0}', 'ترشّح'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
      );
}
