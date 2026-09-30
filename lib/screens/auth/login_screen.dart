import 'dart:async';

import 'package:flutter/material.dart';

import 'register_screen.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/app_logo.dart';
import '../library/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().login(_email.text.trim(), _password.text);
      if (mounted) {
        Navigator.of(
          context,
        ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.statusCode == 401
            ? 'بيانات الدخول غير صحيحة'
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

  Future<void> _googleLogin() async {
    // سيتم تطويره لاحقاً مع google_sign_in package
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('سيتم إضافة خاصية جوجل قريباً')));
  }

  Future<void> _facebookLogin() async {
    // سيتم تطويره لاحقاً مع facebook_flutter package
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('سيتم إضافة خاصية فيسبوك قريباً')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const AppLogo(size: 88),
                  const SizedBox(height: 20),
                  Text(
                    'أساتذة',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'مكتبة رقمية تعليمية للملفات',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty || !v.contains('@')) ? 'أدخل بريداً صحيحاً' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: !_passwordVisible,
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
                    validator: (v) => (v == null || v.isEmpty) ? 'أدخل كلمة المرور' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  LoadingButton(loading: _loading, onPressed: _login, text: 'تسجيل الدخول'),
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

                  // زر تسجيل الدخول بجوجل
                  OutlinedButton.icon(
                    onPressed: _googleLogin,
                    icon: const Icon(Icons.g_translate),
                    label: const Text('الدخول بحساب جوجل'),
                  ),
                  const SizedBox(height: 8),

                  // زر تسجيل الدخول بفيسبوك
                  OutlinedButton.icon(
                    onPressed: _facebookLogin,
                    icon: const Icon(Icons.facebook),
                    label: const Text('الدخول بحساب فيسبوك'),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('ليس لديك حساب؟'),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text('إنشاء حساب'),
                      ),
                    ],
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
