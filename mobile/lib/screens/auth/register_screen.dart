import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

/// إنشاء حساب مع اختيار نوعه: باحث عن عمل أو مؤسسة (3.1)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  String _role = 'seeker';
  String? _wilaya;
  bool _obscure = true;
  bool _loading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      showSnack(context, 'يجب الموافقة على الشروط وسياسة الخصوصية', error: true);
      return;
    }
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    try {
      final devOtp = await context.read<AuthProvider>().register(
            fullName: _fullName.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
            role: _role,
            email: _email.text.trim(),
            wilaya: _wilaya,
          );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(phone: _phone.text.trim(), devOtp: devOtp),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب جديد')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // اختيار نوع الحساب
                const Text('نوع الحساب',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        selected: _role == 'seeker',
                        icon: PhosphorIcons.userFocus(PhosphorIconsStyle.fill),
                        title: 'باحث عن عمل',
                        subtitle: 'أبحث عن وظيفة',
                        onTap: () => setState(() => _role = 'seeker'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        selected: _role == 'company',
                        icon: PhosphorIcons.briefcase(PhosphorIconsStyle.fill),
                        title: 'مؤسسة',
                        subtitle: 'أبحث عن موظفين',
                        onTap: () => setState(() => _role = 'company'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _label(_role == 'company' ? 'اسم المسؤول *' : 'الاسم الكامل *'),
                TextFormField(
                  controller: _fullName,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'أحمد بن يوسف',
                    prefixIcon: Icon(PhosphorIcons.identificationCard(PhosphorIconsStyle.regular)),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.length < 3) return 'الاسم يجب ألّا يقلّ عن 3 أحرف';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _label('رقم الهاتف *'),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: '0555123456',
                    prefixIcon: Icon(PhosphorIcons.phone(PhosphorIconsStyle.bold)),
                    helperText: 'سيصلك رمز تأكيد عبر رسالة قصيرة',
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (!RegExp(r'^0[5-7]\d{8}$').hasMatch(t)) {
                      return 'رقم جزائري صالح يبدأ بـ 05 أو 06 أو 07';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _label('البريد الإلكتروني (اختياري)'),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'ahmed@gmail.com',
                    prefixIcon: Icon(PhosphorIcons.envelopeSimple(PhosphorIconsStyle.bold)),
                  ),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(t)) {
                      return 'بريد إلكتروني غير صالح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _label('الولاية'),
                DropdownButtonFormField<String>(
                  initialValue: _wilaya,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(PhosphorIcons.mapPin(PhosphorIconsStyle.regular)),
                  ),
                  hint: const Text('اختر الولاية'),
                  items: Labels.wilayas
                      .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                      .toList(),
                  onChanged: (v) => setState(() => _wilaya = v),
                ),
                const SizedBox(height: 16),

                _label('كلمة المرور *'),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: '6 محارف على الأقل',
                    prefixIcon: Icon(PhosphorIcons.lock(PhosphorIconsStyle.bold)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? PhosphorIcons.eye(PhosphorIconsStyle.bold)
                          : PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold)),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'كلمة المرور يجب ألّا تقلّ عن 6 محارف'
                      : null,
                ),
                const SizedBox(height: 12),

                // الموافقة الصريحة — القانون 18-07
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'أوافق على شروط الاستعمال وسياسة الخصوصية',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
                const SizedBox(height: 8),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('إنشاء الحساب'),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('لديك حساب بالفعل؟',
                        style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text('سجّل الدخول'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
      );
}

class _RoleCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.07)
                : AppColors.surface,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.8 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 30,
                  color: selected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
}
