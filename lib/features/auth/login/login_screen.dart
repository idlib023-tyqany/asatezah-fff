import 'dart:async';

import 'package:flutter/material.dart';

import '../register/register_screen.dart';

import 'package:asatezah/core/network/api_service.dart';
import 'package:asatezah/features/auth/auth_service.dart';
import 'package:asatezah/features/auth/social_auth_service.dart';
import 'package:asatezah/features/library/home/home_screen.dart';

import './login_view.dart';

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
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
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

  Future<void> _googleLogin() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final idToken = await SocialAuthService.signInWithGoogle();
      await AuthService().loginWithGoogle(idToken);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } on SocialAuthException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.message.isNotEmpty
              ? error.message
              : 'فشل تسجيل الدخول عبر Google.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'تعذّر تسجيل الدخول عبر Google. تحقق من إعدادات Firebase/Supabase.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _facebookLogin() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final accessToken = await SocialAuthService.signInWithFacebook();
      await AuthService().loginWithFacebook(accessToken);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } on SocialAuthException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.message.isNotEmpty
              ? error.message
              : 'فشل تسجيل الدخول عبر Facebook.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'تعذّر تسجيل الدخول عبر Facebook. تحقق من إعدادات Facebook Login.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _passwordVisible = !_passwordVisible);
  }

  void _openRegister() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
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
      onGoogleLogin: _googleLogin,
      onFacebookLogin: _facebookLogin,
      onRegister: _openRegister,
    );
  }
}
