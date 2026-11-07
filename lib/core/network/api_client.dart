import 'dart:async';

import 'package:dio/dio.dart';

import 'api_config.dart';

class ApiClient {
  ApiClient._() {
    final baseUrl = ApiConfig.baseUrl.endsWith('/') ? ApiConfig.baseUrl : '${ApiConfig.baseUrl}/';
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.connectTimeout,
        headers: const {'Accept': 'application/json', 'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final requestedToken = options.extra['authToken'];
          final token = requestedToken is String && requestedToken.isNotEmpty
              ? requestedToken
              : _token;

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }

          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _token = null;
            final callback = onUnauthorized;
            if (callback != null) {
              unawaited(callback());
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._();

  factory ApiClient() => _instance;

  late final Dio dio;
  String? _token;
  Future<void> Function()? onUnauthorized;

  String? get token => _token;

  void setToken(String? value) {
    _token = value;
  }

  String normalizePath(String endpoint) => endpoint.replaceFirst(RegExp(r'^/+'), '');
}
