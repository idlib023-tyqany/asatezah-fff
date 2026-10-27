import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/network/api_config.dart';

class SocialAuthException implements Exception {
  const SocialAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SocialAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _googleSignInInitialization;

  static Future<String> signInWithGoogle() async {
    try {
      if (ApiConfig.googleServerClientId.isEmpty) {
        throw const SocialAuthException(
          'لم يتم ضبط Google OAuth. أعد بناء التطبيق مع GOOGLE_SERVER_CLIENT_ID الخاص بعميل Web OAuth.',
        );
      }

      final initialization = _googleSignInInitialization ??= _googleSignIn
          .initialize(serverClientId: ApiConfig.googleServerClientId);
      try {
        await initialization;
      } catch (_) {
        _googleSignInInitialization = null;
        rethrow;
      }
      final account = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );

      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const SocialAuthException(
          'تعذّر الحصول على هوية Google. تحقق من إعدادات Firebase/Supabase وتفعيل SHA-1 وSHA-256 في لوحة التحكم.',
        );
      }

      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const SocialAuthException('تم إلغاء تسجيل الدخول بواسطة Google.');
      }
      throw const SocialAuthException(
        'تعذّر تسجيل الدخول بحساب Google. تحقق من إعداد GOOGLE_SERVER_CLIENT_ID وبصمات SHA-1 وSHA-256 وحزمة Android في Google Cloud.',
      );
    } on SocialAuthException {
      rethrow;
    } catch (_) {
      throw const SocialAuthException(
        'تعذّر تسجيل الدخول بحساب Google. تحقق من إعداد GOOGLE_SERVER_CLIENT_ID وبصمات SHA-1 وSHA-256 وحزمة Android في Google Cloud.',
      );
    }
  }

  static Future<String> signInWithFacebook() async {
    try {
      if (ApiConfig.facebookAppId.isEmpty) {
        throw const SocialAuthException(
          'لم يتم ضبط FACEBOOK_APP_ID عند بناء التطبيق. أعد البناء باستخدام معرّف تطبيق Facebook نفسه الموجود في Android auth.properties.',
        );
      }

      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        throw const SocialAuthException('تم إلغاء تسجيل الدخول بواسطة فيسبوك.');
      }

      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw const SocialAuthException(
          'تعذّر إكمال تسجيل الدخول عبر فيسبوك. تأكد من تفعيل التطبيق في Facebook Login وتحديث إعدادات SDK.',
        );
      }

      final token = result.accessToken!.tokenString;
      if (token.isEmpty) {
        throw const SocialAuthException(
          'تعذّر الحصول على رمز هوية فيسبوك. تحقق من إعدادات تطبيق Facebook والـ API endpoint.',
        );
      }

      return token;
    } on SocialAuthException {
      rethrow;
    } catch (_) {
      throw const SocialAuthException(
        'تعذّر تسجيل الدخول بحساب فيسبوك. تحقق من إعدادات Facebook Login والـ API endpoint.',
      );
    }
  }
}
