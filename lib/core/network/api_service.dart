import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'api_config.dart';

/// Compatibility facade used by feature services for all API requests.
class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  final ApiClient _client = ApiClient();

  Future<void> Function()? get onUnauthorized => _client.onUnauthorized;

  set onUnauthorized(Future<void> Function()? callback) {
    _client.onUnauthorized = callback;
  }

  String? get token => _client.token;

  bool get isAuthenticated => token?.isNotEmpty ?? false;

  /// Authentication state is restored by [AuthService] from secure storage.
  ///
  /// Keep this method for the existing application start-up contract, but do
  /// not persist bearer tokens in SharedPreferences: that storage is not meant
  /// for credentials.
  Future<void> init() async {}

  Future<void> setToken(String? value) async {
    _client.setToken(value);
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    String? token,
  }) => _request('GET', endpoint, queryParameters: queryParams, token: token);

  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body, String? token}) =>
      _request('POST', endpoint, data: body, token: token);

  Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? body, String? token}) =>
      _request('PUT', endpoint, data: body, token: token);

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) => _request('PATCH', endpoint, data: body, token: token);

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) => _request('DELETE', endpoint, data: body, token: token);

  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    String filePath, {
    Map<String, String>? fields,
    String fileField = 'file',
    String? token,
  }) async {
    if (kReleaseMode && (!ApiConfig.hasProductionApiUrl || !ApiConfig.hasProductionStorageUrl)) {
      throw const ApiException(
        statusCode: 0,
        message: 'عناوين API أو التخزين غير مضبوطة للإصدار. أعد البناء باستخدام API_BASE_URL وSTORAGE_BASE_URL يشيران إلى خادم HTTPS.',
      );
    }

    try {
      final formData = FormData.fromMap({
        ...?fields,
        fileField: await MultipartFile.fromFile(filePath),
      });
      return await _request('POST', endpoint, data: formData, token: token);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Object? data,
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    try {
      final response = await _client.dio.request<dynamic>(
        _client.normalizePath(endpoint),
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method, extra: token == null ? null : {'authToken': token}),
      );
      return _normalizeResponse(response.data);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Map<String, dynamic> _normalizeResponse(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }

  ApiException _toApiException(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final responseData = error.response?.data;
    final responseMap = responseData is Map ? Map<String, dynamic>.from(responseData) : null;
    final rawMessage = responseMap?['message'];

    final message = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'انتهت مهلة الاتصال بالخادم، يرجى المحاولة لاحقاً.',
      DioExceptionType.connectionError => 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مجدداً.',
      DioExceptionType.badCertificate => 'تعذّر إنشاء اتصال آمن بالخادم.',
      DioExceptionType.cancel => 'تم إلغاء الطلب.',
      _ => switch (statusCode) {
        401 => 'انتهت جلسة الدخول. سجّل الدخول مجدداً.',
        >= 500 => 'حدث خطأ في الخادم. يرجى المحاولة لاحقاً.',
        _ when rawMessage is String && rawMessage.isNotEmpty => rawMessage,
        _ => 'تعذّر إكمال الطلب. يرجى المحاولة مجدداً.',
      },
    };

    final rawErrors = responseMap?['errors'];
    final errors = rawErrors is Map ? Map<String, dynamic>.from(rawErrors) : null;

    return ApiException(statusCode: statusCode, message: message, errors: errors);
  }
}

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message, this.errors});

  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  @override
  String toString() => message;
}
