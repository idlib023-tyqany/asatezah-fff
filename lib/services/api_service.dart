import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiService {
  static const Duration _requestTimeout = Duration(seconds: 15);
  static String? _token;
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;
  ApiService._internal();

  Future<void> Function()? onUnauthorized;

  /// تهيئة الخدمة وقراءة التوكن المخزن
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  String? get token => _token;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Map<String, String> _getHeaders({String? token}) {
    final activeToken = (token != null && token.isNotEmpty) ? token : _token;
    final h = <String, String>{'Accept': 'application/json', 'Content-Type': 'application/json'};
    if (activeToken != null && activeToken.isNotEmpty) {
      h['Authorization'] = 'Bearer $activeToken';
    }
    return h;
  }

  /// تعيين التوكن وحفظه اختياريًا في ذاكرة الجهاز
  Future<void> setToken(String? value, {bool persist = true}) async {
    _token = value;
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      if (value != null && value.isNotEmpty) {
        await prefs.setString('auth_token', value);
      } else {
        await prefs.remove('auth_token');
      }
    }
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint').replace(queryParameters: queryParams);
    final response = await http
        .get(uri, headers: _getHeaders(token: token))
        .timeout(_requestTimeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await http
        .post(
          uri,
          headers: _getHeaders(token: token),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_requestTimeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await http
        .put(
          uri,
          headers: _getHeaders(token: token),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_requestTimeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await http
        .patch(
          uri,
          headers: _getHeaders(token: token),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_requestTimeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final request = http.Request('DELETE', uri);
    request.headers.addAll(_getHeaders(token: token));
    if (body != null) {
      request.body = jsonEncode(body);
    }
    final streamed = await request.send().timeout(_requestTimeout);
    final response = await http.Response.fromStream(streamed).timeout(_requestTimeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    String filePath, {
    Map<String, String>? fields,
    String fileField = 'file',
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(_getHeaders(token: token));
    request.headers['Accept'] = 'application/json';
    request.headers.remove('Content-Type');

    if (fields != null) {
      request.fields.addAll(fields);
    }
    request.files.add(await http.MultipartFile.fromPath(fileField, filePath));

    final streamed = await request.send().timeout(_requestTimeout);
    final response = await http.Response.fromStream(streamed).timeout(_requestTimeout);
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic body;

    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } on FormatException {
        body = {'message': 'استجابة غير متوقعة من السيرفر.'};
      }
    } else {
      body = {};
    }

    // التعامل مع حالة انتهاء التوكن أو عدم التصريح
    if (response.statusCode == 401) {
      setToken(null);
      final callback = onUnauthorized;
      if (callback != null) {
        unawaited(callback());
      }
    }

    // الاستجابات الناجحة (200 - 299)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic>) {
        return body;
      } else if (body is List) {
        return {'data': body};
      }
      return {'data': body};
    }

    // الاستجابات المحملة بأخطاء
    final String errorMessage = body is Map<String, dynamic>
        ? (body['message'] ?? 'حدث خطأ في الاتصال بالخادم')
        : 'حدث خطأ في الاتصال بالخادم';

    final dynamic errors = body is Map<String, dynamic> ? body['errors'] : null;

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
      errors: errors is Map<String, dynamic> ? errors : null,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  ApiException({required this.statusCode, required this.message, this.errors});

  @override
  String toString() => message;
}
