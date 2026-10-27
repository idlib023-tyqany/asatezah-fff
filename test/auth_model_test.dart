import 'package:asatezah/features/auth/login/login_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User', () {
    test('parses API values and preserves profile fields', () {
      final user = User.fromJson({
        'id': '42',
        'name': 'Test User',
        'email': 'test@example.com',
        'role': 'admin',
        'can_contribute': 'true',
        'specialization': 'Mathematics',
      });

      expect(user.id, 42);
      expect(user.isAdmin, isTrue);
      expect(user.canContribute, isTrue);
      expect(user.specialization, 'Mathematics');
      expect(User.fromJson(user.toJson()), user);
    });

    test('uses safe defaults for missing profile fields', () {
      final user = User.fromJson(const {});

      expect(user.id, 0);
      expect(user.role, 'user');
      expect(user.canContribute, isFalse);
      expect(user.isAdmin, isFalse);
    });
  });
}
