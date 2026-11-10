import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'otp_model.dart';

class OtpView extends StatelessWidget {
  const OtpView({
    required this.challenge,
    required this.emailCode,
    required this.phoneCode,
    required this.isLoading,
    required this.error,
    required this.onVerify,
    required this.onResend,
    super.key,
  });

  final OtpChallenge challenge;
  final TextEditingController emailCode;
  final TextEditingController phoneCode;
  final bool isLoading;
  final String? error;
  final VoidCallback onVerify;
  final VoidCallback onResend;

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
                if (challenge.channels.contains('email'))
                  _codeField(
                    controller: emailCode,
                    label:
                        'رمز البريد ${challenge.destinations['email'] ?? ''}',
                  ),
                if (challenge.channels.contains('phone')) ...[
                  const SizedBox(height: 12),
                  _codeField(
                    controller: phoneCode,
                    label:
                        'رمز الهاتف ${challenge.destinations['phone'] ?? ''}',
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isLoading ? null : onVerify,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('تأكيد'),
                ),
                TextButton(
                  onPressed: isLoading ? null : onResend,
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
