import 'package:asatezah/features/auth/auth_service.dart';

import 'otp_model.dart';

class OtpService {
  OtpService({AuthService? auth}) : _auth = auth ?? AuthService();

  final AuthService _auth;

  Future<void> verify(
    OtpChallenge challenge, {
    String? emailCode,
    String? phoneCode,
  }) async {
    if (challenge.purpose == 'contact_change') {
      await _auth.verifyContactChange(
        verificationId: challenge.verificationId,
        emailCode: emailCode,
        phoneCode: phoneCode,
      );
      return;
    }

    await _auth.verifyAuthenticationCodes(
      verificationId: challenge.verificationId,
      emailCode: emailCode,
      phoneCode: phoneCode,
    );
  }

  Future<OtpChallenge> resend(OtpChallenge challenge) async {
    final response = challenge.purpose == 'contact_change'
        ? await _auth.resendContactChange(challenge.verificationId)
        : await _auth.resendVerification(challenge.verificationId);
    return OtpChallenge.fromJson(response);
  }
}
