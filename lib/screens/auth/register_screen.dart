import 'dart:async';

import 'package:flutter/material.dart';

import 'login_screen.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_button.dart';
import 'complete_profile_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// البيانات المسبقة للصفوف والمواد (للاستخدام في صفحة إكمال البيانات)
final Map<String, List<String>> classesAndSubjects = {
  'الأول الابتدائي': ['العربية', 'الرياضيات', 'العلوم', 'الاجتماعيات', 'الإنجليزية'],
  'الثاني الابتدائي': ['العربية', 'الرياضيات', 'العلوم', 'الاجتماعيات', 'الإنجليزية'],
  'الثالث الابتدائي': ['العربية', 'الرياضيات', 'العلوم', 'الاجتماعيات', 'الإنجليزية'],
  'الرابع الابتدائي': ['العربية', 'الرياضيات', 'العلوم', 'الاجتماعيات', 'الإنجليزية'],
  'الخامس الابتدائي': ['العربية', 'الرياضيات', 'العلوم', 'الاجتماعيات', 'الإنجليزية'],
  'السادس الابتدائي': ['العربية', 'الرياضيات', 'العلوم', 'الاجتماعيات', 'الإنجليزية'],
  'الأول الإعدادي': ['العربية', 'الرياضيات', 'العلوم', 'الاجتماعيات', 'الإنجليزية', 'الفرنسية'],
  'الثاني الإعدادي': ['العربية', 'الرياضيات', 'العلوم', 'الاجتماعيات', 'الإنجليزية', 'الفرنسية'],
  'الثالث الإعدادي': ['العربية', 'الرياضيات', 'العلوم', 'الاجتماعيات', 'الإنجليزية', 'الفرنسية'],
  'الأول الثانوي': [
    'العربية',
    'الرياضيات',
    'الفيزياء',
    'الكيمياء',
    'الأحياء',
    'الاجتماعيات',
    'الإنجليزية',
  ],
  'الثاني الثانوي': [
    'العربية',
    'الرياضيات',
    'الفيزياء',
    'الكيمياء',
    'الأحياء',
    'الاجتماعيات',
    'الإنجليزية',
  ],
  'الثالث الثانوي': [
    'العربية',
    'الرياضيات',
    'الفيزياء',
    'الكيمياء',
    'الأحياء',
    'الاجتماعيات',
    'الإنجليزية',
  ],
};

// الصفوف المتاحة لمعلم الصف (الابتدائي فقط)
final List<String> primaryClasses = [
  'الأول الابتدائي',
  'الثاني الابتدائي',
  'الثالث الابتدائي',
  'الرابع الابتدائي',
  'الخامس الابتدائي',
  'السادس الابتدائي',
];

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _passwordVisible = false;
  bool _passwordConfirmVisible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService().registerBasic(_email.text.trim(), _password.text, _passwordConfirm.text);

      if (mounted) {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => const CompleteProfileScreen()));
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.statusCode == 422
            ? (error.message.isNotEmpty ? error.message : 'تحقق من البيانات المدخلة')
            : (error.message.isNotEmpty ? error.message : 'تعذّر الاتصال بالخادم'),
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _error = 'انتهت مهلة الاتصال بالخادم. تحقق من عنوان الـAPI والإنترنت.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذّر الاتصال بالخادم. تحقق من الاتصال وعنوان الـAPI.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignUp() async {
    // سيتم تطويره لاحقاً مع google_sign_in package
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('سيتم إضافة خاصية جوجل قريباً')));
  }

  Future<void> _facebookSignUp() async {
    // سيتم تطويره لاحقاً مع facebook_flutter package
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('سيتم إضافة خاصية فيسبوك قريباً')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // البريد الإلكتروني
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: 'example@email.com',
                    ),
                    validator: (v) => (v == null || !v.contains('@')) ? 'أدخل بريداً صحيحاً' : null,
                  ),
                  const SizedBox(height: 16),

                  // كلمة المرور
                  TextFormField(
                    controller: _password,
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 8) ? 'كلمة المرور 8 أحرف على الأقل' : null,
                  ),
                  const SizedBox(height: 16),

                  // تأكيد كلمة المرور
                  TextFormField(
                    controller: _passwordConfirm,
                    obscureText: !_passwordConfirmVisible,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => _register(),
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordConfirmVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordConfirmVisible = !_passwordConfirmVisible;
                          });
                        },
                      ),
                    ),
                    validator: (v) => (v != _password.text) ? 'كلمة المرور غير متطابقة' : null,
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // زر التسجيل
                  LoadingButton(loading: _loading, onPressed: _register, text: 'إنشاء حساب'),
                  const SizedBox(height: 16),

                  // فاصل
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('أو')),
                        Expanded(child: Divider()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // زر تسجيل جوجل
                  OutlinedButton.icon(
                    onPressed: _googleSignUp,
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text('التسجيل بحساب جوجل'),
                  ),
                  const SizedBox(height: 8),

                  // زر تسجيل فيسبوك
                  OutlinedButton.icon(
                    onPressed: _facebookSignUp,
                    icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                    label: const Text('التسجيل بحساب فيسبوك'),
                  ),
                  const SizedBox(height: 16),

                  // زر الذهاب لتسجيل الدخول
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('لديّ حساب بالفعل'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
