import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asatezah/services/api_service.dart';
import 'package:asatezah/services/auth_service.dart';

void main() {
  test('restores the cached token and user as one authenticated session', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'cached-token',
      'user_data': jsonEncode({
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'role': 'user',
        'can_contribute': true,
      }),
    });

    await AuthService().init();

    expect(AuthService().isAuthenticated, isTrue);
    expect(AuthService().currentUser?.email, 'test@example.com');
    expect(ApiService().token, 'cached-token');
  });

  test('clears an incomplete cached session', () async {
    SharedPreferences.setMockInitialValues({
      'user_data': jsonEncode({
        'id': 1,
        'name': 'Test User',
        'email': 'test@example.com',
        'role': 'user',
        'can_contribute': true,
      }),
    });

    await AuthService().init();
    final prefs = await SharedPreferences.getInstance();

    expect(AuthService().isAuthenticated, isFalse);
    expect(AuthService().currentUser, isNull);
    expect(ApiService().token, isNull);
    expect(prefs.getString('auth_token'), isNull);
    expect(prefs.getString('user_data'), isNull);
  });
}
