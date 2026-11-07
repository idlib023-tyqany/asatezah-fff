import 'dart:async';

import 'package:flutter/material.dart';

import '../login/login_screen.dart';

import 'package:asatezah/core/network/api_service.dart';
import 'package:asatezah/features/auth/auth_service.dart';

import '../otp/otp_verification_screen.dart';

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
  const RegisterScreen({this.previewMode = false, super.key});

  final bool previewMode;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _passwordVisible = false;
  bool _passwordConfirmVisible = false;

  @override
  void dispose() {
    _email.dispose();
    _phoneNumber.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.previewMode) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            previewMode: true,
            challenge: {
              'verification_id': 'dummy_id',
              'email': _email.text.trim(),
              'phone_number': _phoneNumber.text.trim(),
              'channels': ['email', 'phone'],
              'destinations': {
                'email': _email.text.trim(),
                'phone': _phoneNumber.text.trim(),
              },
            },
          ),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final verification = await AuthService().registerBasic(
        _email.text.trim(),
        _phoneNumber.text.trim(),
        _password.text,
        _passwordConfirm.text,
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

  void _togglePasswordVisibility() {
    setState(() => _passwordVisible = !_passwordVisible);
  }

  void _togglePasswordConfirmVisibility() {
    setState(() => _passwordConfirmVisible = !_passwordConfirmVisible);
  }

  void _openLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginScreen(previewMode: widget.previewMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RegisterView(
      formKey: _formKey,
      emailController: _email,
      phoneNumberController: _phoneNumber,
      passwordController: _password,
      passwordConfirmController: _passwordConfirm,
      isLoading: _loading,
      isPasswordVisible: _passwordVisible,
      isPasswordConfirmVisible: _passwordConfirmVisible,
      errorMessage: _error,
      onRegister: _register,
      onPasswordVisibilityChanged: _togglePasswordVisibility,
      onPasswordConfirmVisibilityChanged: _togglePasswordConfirmVisibility,
      onLogin: _openLogin,
    );
  }
}
