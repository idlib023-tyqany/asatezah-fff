import 'dart:async';

import 'package:flutter/material.dart';

import '../login/login_screen.dart';

import 'package:asatezah/core/network/api_service.dart';
import 'package:asatezah/features/auth/auth_service.dart';
import 'package:asatezah/features/auth/social_auth_service.dart';

import '../complete_profile/complete_profile_screen.dart';

import './register_view.dart';

// البيانات المسبقة للصفوف والمواد (يمكن نقلها لملف constants مستقل لاحقاً)
const Map<String, List<String>> classesAndSubjects = {
  'الأول الابتدائي': [
    'العربية',
    'الرياضيات',
    'العلوم',
    'الاجتماعيات',
    'الإنجليزية',
  ],
  'الثاني الابتدائي': [
    'العربية',
    'الرياضيات',
    'العلوم',
    'الاجتماعيات',
    'الإنجليزية',
  ],
  'الثالث الابتدائي': [
    'العربية',
    'الرياضيات',
    'العلوم',
    'الاجتماعيات',
    'الإنجليزية',
  ],
  'الرابع الابتدائي': [
    'العربية',
    'الرياضيات',
    'العلوم',
    'الاجتماعيات',
    'الإنجليزية',
  ],
  'الخامس الابتدائي': [
    'العربية',
    'الرياضيات',
    'العلوم',
    'الاجتماعيات',
    'الإنجليزية',
  ],
  'السادس الابتدائي': [
    'العربية',
    'الرياضيات',
    'العلوم',
    'الاجتماعيات',
    'الإنجليزية',
  ],
  'الأول الإعدادي': [
    'العربية',
    'الرياضيات',
    'العلوم',
    'الاجتماعيات',
    'الإنجليزية',
    'الفرنسية',
  ],
  'الثاني الإعدادي': [
    'العربية',
    'الرياضيات',
    'العلوم',
    'الاجتماعيات',
    'الإنجليزية',
    'الفرنسية',
  ],
  'الثالث الإعدادي': [
    'العربية',
    'الرياضيات',
    'العلوم',
    'الاجتماعيات',
    'الإنجليزية',
    'الفرنسية',
  ],
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

const List<String> primaryClasses = [
  'الأول الابتدائي',
  'الثاني الابتدائي',
  'الثالث الابتدائي',
  'الرابع الابتدائي',
  'الخامس الابتدائي',
  'السادس الابتدائي',
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

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
      await AuthService().registerBasic(
        _email.text.trim(),
        _password.text,
        _passwordConfirm.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.statusCode == 422
            ? (error.message.isNotEmpty
                  ? error.message
                  : 'تحقق من البيانات المدخلة')
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

  Future<void> _googleSignUp() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final idToken = await SocialAuthService.signInWithGoogle();
      await AuthService().loginWithGoogle(idToken);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
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
              : 'فشل التسجيل عبر Google.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'تعذّر التسجيل عبر Google. تحقق من إعدادات Firebase/Supabase.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _facebookSignUp() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final accessToken = await SocialAuthService.signInWithFacebook();
      await AuthService().loginWithFacebook(accessToken);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
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
              : 'فشل التسجيل عبر Facebook.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'تعذّر التسجيل عبر Facebook. تحقق من إعدادات Facebook Login.',
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

  void _togglePasswordConfirmVisibility() {
    setState(() => _passwordConfirmVisible = !_passwordConfirmVisible);
  }

  void _openLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return RegisterView(
      formKey: _formKey,
      emailController: _email,
      passwordController: _password,
      passwordConfirmController: _passwordConfirm,
      isLoading: _loading,
      isPasswordVisible: _passwordVisible,
      isPasswordConfirmVisible: _passwordConfirmVisible,
      errorMessage: _error,
      onRegister: _register,
      onPasswordVisibilityChanged: _togglePasswordVisibility,
      onPasswordConfirmVisibilityChanged: _togglePasswordConfirmVisibility,
      onGoogleSignUp: _googleSignUp,
      onFacebookSignUp: _facebookSignUp,
      onLogin: _openLogin,
    );
  }
}
