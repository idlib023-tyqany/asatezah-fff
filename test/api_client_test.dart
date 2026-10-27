import 'package:asatezah/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final client = ApiClient();

  tearDown(() {
    client.setToken(null);
  });

  test('sends the configured token as a bearer authorization header', () async {
    client.setToken('session-token');
    String? authorizationHeader;
    final interceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        authorizationHeader = options.headers['Authorization'] as String?;
        handler.resolve(
          Response(requestOptions: options, data: <String, bool>{}),
        );
      },
    );
    client.dio.interceptors.add(interceptor);

    try {
      await client.dio.get<dynamic>('user');
    } finally {
      client.dio.interceptors.remove(interceptor);
    }

    expect(authorizationHeader, 'Bearer session-token');
  });

  test('uses the request token when provided', () async {
    client.setToken('session-token');
    String? authorizationHeader;
    final interceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        authorizationHeader = options.headers['Authorization'] as String?;
        handler.resolve(
          Response(requestOptions: options, data: <String, bool>{}),
        );
      },
    );
    client.dio.interceptors.add(interceptor);

    try {
      await client.dio.get<dynamic>(
        'user',
        options: Options(extra: {'authToken': 'request-token'}),
      );
    } finally {
      client.dio.interceptors.remove(interceptor);
    }

    expect(authorizationHeader, 'Bearer request-token');
  });
}
