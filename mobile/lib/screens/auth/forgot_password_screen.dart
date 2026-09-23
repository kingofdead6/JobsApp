import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';

/// استرجاع كلمة المرور برمز يُرسل إلى الهاتف (3.1)
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phone.text.trim();
    if (!RegExp(r'^0[5-7]\d{8}$').hasMatch(phone)) {
      showSnack(context, 'أدخل رقم هاتف جزائري صالح', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.forgotPassword(phone);
      if (!mounted) return;
      setState(() => _codeSent = true);
      showSnack(context, 'إن كان الرقم مسجّلًا فسيصلك رمز الاسترجاع');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (_code.text.trim().length != 6) {
      showSnack(context, 'أدخل الرمز المكوّن من 6 أرقام', error: true);
      return;
    }
    if (_newPassword.text.length < 6) {
      showSnack(context, 'كلمة المرور يجب ألّا تقلّ عن 6 محارف', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.resetPassword(
        _phone.text.trim(),
        _code.text.trim(),
        _newPassword.text,
      );
      if (!mounted) return;
      showSnack(context, 'تم تغيير كلمة المرور، يمكنك الدخول الآن');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => route.isFirst,
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
      appBar: AppBar(
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          title: const Text('استرجاع كلمة المرور')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      size: 42, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _codeSent
                    ? 'أدخل الرمز وكلمة المرور الجديدة'
                    : 'أدخل رقم هاتفك لإرسال رمز الاسترجاع',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _phone,
                enabled: !_codeSent,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  hintText: '0555123456',
                  prefixIcon: Icon(Icons.phone_outlined),
                  labelText: 'رقم الهاتف',
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 10),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    labelText: 'رمز الاسترجاع',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPassword,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 26),
              ElevatedButton(
                onPressed: _loading ? null : (_codeSent ? _reset : _sendCode),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(_codeSent ? 'تغيير كلمة المرور' : 'إرسال الرمز'),
              ),
              if (_codeSent)
                TextButton(
                  onPressed: () => setState(() => _codeSent = false),
                  child: const Text('تغيير رقم الهاتف'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
