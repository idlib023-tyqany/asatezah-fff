import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asatezah/core/network/api_service.dart';
import 'package:asatezah/features/auth/auth_service.dart';
import 'package:asatezah/main.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    required this.challenge,
    this.previewMode = false,
    super.key,
  });

  final Map<String, dynamic> challenge;
  final bool previewMode;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _emailCode = TextEditingController();
  final _phoneCode = TextEditingController();
  late Map<String, dynamic> _challenge;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _challenge = Map<String, dynamic>.from(widget.challenge);
  }

  @override
  void dispose() {
    _emailCode.dispose();
    _phoneCode.dispose();
    super.dispose();
  }

  List<String> get _channels =>
      (_challenge['channels'] as List<dynamic>? ?? const []).cast<String>();

  Future<void> _verify() async {
    if (_channels.contains('email') && _emailCode.text.trim().length != 6) {
      setState(() => _error = 'أدخل رمز البريد المكوّن من 6 أرقام.');
      return;
    }
    if (_channels.contains('phone') && _phoneCode.text.trim().length != 6) {
      setState(() => _error = 'أدخل رمز الهاتف المكوّن من 6 أرقام.');
      return;
    }
    if (widget.previewMode) {
      setState(() => _error = 'وضع المعاينة: لم يتم التحقق من الرموز.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = AuthService();
      final purpose = _challenge['purpose'] as String? ?? 'login';
      final verificationId = _challenge['verification_id'] as String;

      if (purpose == 'contact_change') {
        await auth.verifyContactChange(
          verificationId: verificationId,
          emailCode: _emailCode.text.trim(),
          phoneCode: _phoneCode.text.trim(),
        );
        if (mounted) Navigator.of(context).pop(true);
      } else {
        // ✅ توثيق الدخول والتسجيل وتخزين التوكن في الجهاز
        await auth.verifyAuthenticationCodes(
          verificationId: verificationId,
          emailCode: _emailCode.text.trim(),
          phoneCode: _phoneCode.text.trim(),
        );
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const RootScreen()),
            (route) => false,
          );
        }
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on TimeoutException {
      if (mounted) setState(() => _error = 'انتهت مهلة الاتصال. حاول مجدداً.');
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر التحقق. حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (widget.previewMode) {
      setState(() {
        _error = 'وضع المعاينة: لم يتم إرسال أي رموز.';
        _emailCode.clear();
        _phoneCode.clear();
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = AuthService();
      final purpose = _challenge['purpose'] as String? ?? 'login';
      final verificationId = _challenge['verification_id'] as String;

      if (purpose == 'contact_change') {
        _challenge = await auth.resendContactChange(verificationId);
      } else {
        _challenge = await auth.resendVerification(verificationId);
      }
      _emailCode.clear();
      _phoneCode.clear();
      if (mounted) setState(() {});
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر إعادة إرسال الرموز.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _codeField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      maxLength: 6,
      textAlign: TextAlign.center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations =
        _challenge['destinations'] as Map<String, dynamic>? ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد رمز التحقق'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.verified_user_outlined, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'أدخل الرموز المرسلة إليك',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_channels.contains('email'))
                  _codeField(
                    controller: _emailCode,
                    label: 'رمز البريد ${destinations['email'] ?? ''}',
                  ),
                if (_channels.contains('phone')) ...[
                  const SizedBox(height: 12),
                  _codeField(
                    controller: _phoneCode,
                    label: 'رمز الهاتف ${destinations['phone'] ?? ''}',
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loading ? null : _verify,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('تأكيد'),
                ),
                TextButton(
                  onPressed: _loading ? null : _resend,
                  child: const Text('إعادة إرسال الرموز'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
