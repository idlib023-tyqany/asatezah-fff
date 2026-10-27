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

      _currentUser = User.fromJson(jsonDecode(userData) as Map<String, dynamic>);
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
  Future<void> login(String email, String password) async {
    final result = await _api.post('/login', body: {'email': email.trim(), 'password': password});
    await _handleAuthSuccess(result);
  }

  /// تسجيل حساب جديد (أساسي)
  Future<void> registerBasic(String email, String password, String passwordConfirmation) async {
    final body = <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
    final result = await _api.post('/register', body: body);
    await _handleAuthSuccess(result);
  }

  /// تسجيل حساب جديد (تفصيلي)
  Future<void> register(
    String name,
    String email,
    String password,
    String passwordConfirmation, {
    String? specialization,
    String? displayName,
    String? phoneNumber,
    String? idNumber,
    String? trainerType,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (_isNotBlank(specialization)) 'specialization': specialization!.trim(),
      if (_isNotBlank(displayName)) 'display_name': displayName!.trim(),
      if (_isNotBlank(phoneNumber)) 'phone_number': phoneNumber!.trim(),
      if (_isNotBlank(idNumber)) 'id_number': idNumber!.trim(),
      if (_isNotBlank(trainerType)) 'trainer_type': trainerType!.trim(),
    };

    final result = await _api.post('/register', body: body);
    await _handleAuthSuccess(result);
  }

  /// تسجيل الدخول عبر جوجل
  Future<void> loginWithGoogle(String idToken) async {
    final result = await _api.post('/auth/google', body: {'id_token': idToken});
    await _handleAuthSuccess(result);
  }

  /// تسجيل الدخول عبر فيسبوك
  Future<void> loginWithFacebook(String accessToken) async {
    final result = await _api.post('/auth/facebook', body: {'access_token': accessToken});
    await _handleAuthSuccess(result);
  }

  /// تحديث بيانات الملف الشخصي
  Future<void> updateProfile({
    String? name,
    String? displayName,
    String? phoneNumber,
    String? trainerType,
    String? specialization,
  }) async {
    final body = <String, dynamic>{
      if (_isNotBlank(name)) 'name': name!.trim(),
      if (_isNotBlank(displayName)) 'display_name': displayName!.trim(),
      if (_isNotBlank(phoneNumber)) 'phone_number': phoneNumber!.trim(),
      if (_isNotBlank(trainerType)) 'trainer_type': trainerType!.trim(),
      if (_isNotBlank(specialization)) 'specialization': specialization!.trim(),
    };

    final result = await _api.put('/profile/update', body: body);
    _currentUser = User.fromJson(result['user'] as Map<String, dynamic>);
    await _saveSession();
    notifyListeners();
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
    await _api.delete('/account', body: <String, dynamic>{'password': password});
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
    final token = _token;
    final user = _currentUser;

    if (token == null || token.isEmpty || user == null) {
      await _clearSession();
      return;
    }

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
