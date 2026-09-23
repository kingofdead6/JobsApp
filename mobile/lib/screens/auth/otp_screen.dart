import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../widgets/common.dart';
import '../main_shell.dart';

/// تأكيد رقم الهاتف برمز SMS (3.1)
class OtpScreen extends StatefulWidget {
  final String phone;
  final String? devOtp;

  const OtpScreen({super.key, required this.phone, this.devOtp});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // في وضع التطوير يصل الرمز في الاستجابة، فنملأه تسهيلًا للاختبار
    if (widget.devOtp != null) _code.text = widget.devOtp!;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      showSnack(context, 'أدخل الرمز المكوّن من 6 أرقام', error: true);
      return;
    }
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().verifyOtp(widget.phone, code);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await AuthService.resendOtp(widget.phone);
      if (mounted) {
        showSnack(context, 'تم إرسال رمز جديد');
        _startTimer();
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد رقم الهاتف')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIcons.chatCircleText(PhosphorIconsStyle.duotone),
                      size: 46, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'أدخل رمز التأكيد',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'أرسلنا رمزًا مكوّنًا من 6 أرقام إلى الرقم\n${widget.phone}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13.5, color: AppColors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 14,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: TextStyle(letterSpacing: 14, fontSize: 26),
                ),
                onSubmitted: (_) => _verify(),
              ),

              if (widget.devOtp != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'وضع التطوير: الرمز ${widget.devOtp}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.warning),
                  ),
                ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('تأكيد'),
              ),
              const SizedBox(height: 14),

              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'يمكنك طلب رمز جديد بعد $_secondsLeft ثانية',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary),
                      )
                    : TextButton.icon(
                        onPressed: _resend,
                        icon: Icon(PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold), size: 18),
                        label: const Text('إعادة إرسال الرمز'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
