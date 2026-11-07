import 'dart:async';

import 'package:flutter/material.dart';

import '../register/register_screen.dart';

import 'package:asatezah/core/network/api_service.dart';
import 'package:asatezah/features/auth/auth_service.dart';

import '../otp/otp_verification_screen.dart';

import './login_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.previewMode = false, super.key});

  final bool previewMode;

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

    if (widget.previewMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وضع المعاينة: لم يتم الاتصال بالخادم.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final verification = await AuthService().login(
        _email.text.trim(),
        _password.text,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(challenge: verification),
          ),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.statusCode == 401
            ? 'بيانات الدخول غير صحيحة'
            : (error.message.isNotEmpty
                  ? error.message
                  : 'تعذّر الاتصال بالخادم'),
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(
        () => _error =
            'انتهت مهلة الاتصال بالخادم. تحقق من عنوان الـAPI والإنترنت.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'تعذّر الاتصال بالخادم. تحقق من الاتصال وعنوان الـAPI.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _passwordVisible = !_passwordVisible);
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(previewMode: widget.previewMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoginView(
      formKey: _formKey,
      emailController: _email,
      passwordController: _password,
      isLoading: _loading,
      isPasswordVisible: _passwordVisible,
      errorMessage: _error,
      onLogin: _login,
      onPasswordVisibilityChanged: _togglePasswordVisibility,
      onRegister: _openRegister,
    );
  }
}
