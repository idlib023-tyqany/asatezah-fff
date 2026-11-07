import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asatezah/core/network/api_service.dart';

import 'login_model.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api;
  final FlutterSecureStorage _secureStorage;

  User? _currentUser;
  String? _token;
  bool _debugSkipAuth = false;

  // مفاتيح التخزين
  static const String _keyUserData = 'user_data';
  static const String _keyAuthToken = 'auth_token';

  /// دعم Dependency Injection لسهولة الـ Testing
  AuthService({ApiService? apiService, FlutterSecureStorage? secureStorage})
    : _api = apiService ?? ApiService(),
      _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _api.onUnauthorized = _clearSession;
  }

  User? get currentUser => _currentUser;

  bool get isAuthenticated {
    if (kDebugMode && _debugSkipAuth) {
      return true;
    }
    return _currentUser != null && _api.isAuthenticated;
  }

  /// تفعيل وضع التطوير - تجاوز تسجيل الدخول
  Future<void> enableDebugMode() async {
    if (!kDebugMode) return;

    _debugSkipAuth = true;
    _currentUser = const User(
      id: 1,
      name: 'مستخدم تطوير',
      email: 'dev@test.com',
      role: 'user',
      canContribute: true,
      specialization: 'تطوير',
    );
    notifyListeners();
  }

  /// تعطيل وضع التطوير
  Future<void> disableDebugMode() async {
    if (!kDebugMode) return;

    _debugSkipAuth = false;
    await _clearSession();
  }

  /// تهيئة الجلسة وقراءة بيانات المستخدم والتأكد من صحة التوكن
  Future<void> init() async {
    await _api.init();

    try {
      _token = await _secureStorage.read(key: _keyAuthToken);
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_keyUserData);

      if (_token == null || _token!.isEmpty || userData == null) {
        await _clearSession();
        return;
      }

      _currentUser = User.fromJson(
        jsonDecode(userData) as Map<String, dynamic>,
      );
      await _api.setToken(_token);

      // التحقق من صحة التوكن من خلال الخادم عند فتح التطبيق
      await _api.get('/user');
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _clearSession();
      }
    } catch (e) {
      // في حالة وجود خطأ في فك ترميز JSON أو مشكلة بالشبكة
      if (_currentUser == null) {
        await _clearSession();
      }
    }
  }

  /// تسجيل الدخول بالبريد وكلمة المرور
  Future<Map<String, dynamic>> login(String email, String password) {
    return _api.post(
      '/login',
      body: {'email': email.trim(), 'password': password},
    );
  }

  /// تسجيل حساب جديد (أساسي)
  Future<Map<String, dynamic>> registerBasic(
    String email,
    String phoneNumber,
    String password,
    String passwordConfirmation,
  ) {
    final body = <String, dynamic>{
      'email': email.trim(),
      'phone_number': phoneNumber.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
    return _api.post('/register', body: body);
  }

  /// تسجيل حساب جديد (تفصيلي)
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String passwordConfirmation, {
    required String phoneNumber,
    String? specialization,
    String? displayName,
    String? idNumber,
    String? trainerType,
  }) {
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'phone_number': phoneNumber.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (_isNotBlank(specialization)) 'specialization': specialization!.trim(),
      if (_isNotBlank(displayName)) 'display_name': displayName!.trim(),
      if (_isNotBlank(idNumber)) 'id_number': idNumber!.trim(),
      if (_isNotBlank(trainerType)) 'trainer_type': trainerType!.trim(),
    };

    return _api.post('/register', body: body);
  }

  /// تحديث بيانات الملف الشخصي
  Future<void> updateProfile({
    String? name,
    String? displayName,
    String? trainerType,
    String? specialization,
  }) async {
    final body = <String, dynamic>{
      if (_isNotBlank(name)) 'name': name!.trim(),
      if (_isNotBlank(displayName)) 'display_name': displayName!.trim(),
      if (_isNotBlank(trainerType)) 'trainer_type': trainerType!.trim(),
      if (_isNotBlank(specialization)) 'specialization': specialization!.trim(),
    };

    final result = await _api.put('/profile/update', body: body);
    _currentUser = User.fromJson(result['user'] as Map<String, dynamic>);
    _token ??= _api.token;
    await _saveSession();
    notifyListeners();
  }

  Future<Map<String, dynamic>> requestContactChange({
    String? email,
    String? phoneNumber,
  }) {
    return _api.post(
      '/profile/contact-change',
      body: {
        if (_isNotBlank(email)) 'email': email!.trim(),
        if (_isNotBlank(phoneNumber)) 'phone_number': phoneNumber!.trim(),
      },
    );
  }

  Future<void> verifyContactChange({
    required String verificationId,
    String? emailCode,
    String? phoneCode,
  }) async {
    final result = await _api.post(
      '/profile/contact-change/verify',
      body: {
        'verification_id': verificationId,
        if (_isNotBlank(emailCode)) 'email_code': emailCode!.trim(),
        if (_isNotBlank(phoneCode)) 'phone_code': phoneCode!.trim(),
      },
    );
    _currentUser = User.fromJson(result['user'] as Map<String, dynamic>);
    _token ??= _api.token;
    await _saveSession();
    notifyListeners();
  }

  Future<Map<String, dynamic>> resendContactChange(String verificationId) {
    return _api.post(
      '/profile/contact-change/resend',
      body: {'verification_id': verificationId},
    );
  }

  Future<void> verifyAuthenticationCodes({
    required String verificationId,
    String? emailCode,
    String? phoneCode,
  }) async {
    final result = await _api.post(
      '/verification/confirm',
      body: {
        'verification_id': verificationId,
        if (_isNotBlank(emailCode)) 'email_code': emailCode!.trim(),
        if (_isNotBlank(phoneCode)) 'phone_code': phoneCode!.trim(),
      },
    );
    await _handleAuthSuccess(result);
  }

  Future<Map<String, dynamic>> resendVerification(String verificationId) {
    return _api.post(
      '/verification/resend',
      body: {'verification_id': verificationId},
    );
  }

  Future<User> refreshCurrentUser() async {
    final response = await _api.get('/user');
    final userData = response['user'];
    if (userData is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 0,
        message: 'تعذّر تحميل بيانات الحساب.',
      );
    }

    _currentUser = User.fromJson(userData);
    _token ??= _api.token;
    await _saveSession();
    notifyListeners();
    return _currentUser!;
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } catch (_) {
      // إكمال مسح الجلسة حتى لو فشل طلب الـ API
    } finally {
      await _clearSession();
    }
  }

  /// حذف الحساب نهائياً
  Future<void> deleteAccount(String password) async {
    await _api.delete(
      '/account',
      body: <String, dynamic>{'password': password},
    );
    await _clearSession();
  }

  // --- دوال مساعدة خاصة (Private Helpers) ---

  /// توحيد طريقة معالجة الاستجابة الناجحة لتسجيل الدخول والتسجيل
  Future<void> _handleAuthSuccess(Map<String, dynamic> response) async {
    _token = response['token'] as String;
    _currentUser = User.fromJson(response['user'] as Map<String, dynamic>);
    await _saveSession();
    notifyListeners();
  }

  /// حفظ البيانات محلياً وفي `ApiService`
  Future<void> _saveSession() async {
    final token = _token ?? _api.token;
    final user = _currentUser;

    if (token == null || token.isEmpty || user == null) {
      await _clearSession();
      return;
    }

    _token = token;
    await _api.setToken(token);
    await _secureStorage.write(key: _keyAuthToken, value: token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, jsonEncode(user.toJson()));
  }

  /// مسح الجلسة نهائياً وتفريغ البيانات
  Future<void> _clearSession() async {
    final hadSession = _token != null || _currentUser != null;

    _token = null;
    _currentUser = null;
    await _api.setToken(null);

    await _secureStorage.delete(key: _keyAuthToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserData);

    if (hadSession) {
      notifyListeners();
    }
  }

  /// التحقق من أن النص ليس null ولا فارغاً
  bool _isNotBlank(String? value) => value != null && value.trim().isNotEmpty;
}
