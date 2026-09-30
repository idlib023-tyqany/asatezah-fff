import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asatezah/main.dart';
import 'package:asatezah/services/auth_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService().init();
  });

  testWidgets('guest launch shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AsatezahApp());
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('ليس لديك حساب؟'), findsOneWidget);
  });

  testWidgets('login validates required fields before making a request', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AsatezahApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.text('أدخل بريداً صحيحاً'), findsOneWidget);
    expect(find.text('أدخل كلمة المرور'), findsOneWidget);
  });

  testWidgets('guest can navigate to registration', (WidgetTester tester) async {
    await tester.pumpWidget(const AsatezahApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('إنشاء حساب'));
    await tester.pumpAndSettle();

    expect(find.text('الاسم الكامل'), findsOneWidget);
    expect(find.text('تأكيد كلمة المرور'), findsOneWidget);
  });
}
