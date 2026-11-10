import 'package:flutter/material.dart';

import 'package:asatezah/core/network/api_service.dart';
import 'package:asatezah/features/auth/auth_service.dart';
import 'package:asatezah/features/auth/login/login_model.dart';
import 'package:asatezah/features/auth/otp/otp_verification_widget.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({this.previewMode = false, super.key});

  final bool previewMode;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  User? _user;

  @override
  void initState() {
    super.initState();
    if (widget.previewMode) {
      _user = const User(
        id: -1,
        name: 'مستخدم تجريبي',
        email: 'test@example.com',
        phoneNumber: '+963912345678',
        role: 'user',
        canContribute: false,
        emailVerified: true,
        phoneVerified: true,
      );
      _email.text = _user!.email;
      _phone.text = _user!.phoneNumber!;
      _loading = false;
    } else {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      await _auth.init();
      final user = _auth.currentUser ?? await _auth.refreshCurrentUser();
      _email.text = user.email;
      _phone.text = user.phoneNumber ?? '';
      if (mounted) setState(() => _user = user);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر تحميل معلومات الحساب.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveContactDetails() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _user;
    if (user == null) return;
    final newEmail = _email.text.trim();
    final newPhone = _phone.text.trim();
    final emailChanged = newEmail.toLowerCase() != user.email.toLowerCase();
    final phoneChanged = newPhone != (user.phoneNumber ?? '');

    if (!emailChanged && !phoneChanged) {
      setState(() => _error = 'لا توجد تغييرات جديدة لحفظها.');
      return;
    }

    if (widget.previewMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('وضع المعاينة: لن يتم حفظ بيانات الحساب.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final challenge = await _auth.requestContactChange(
        email: emailChanged ? newEmail : null,
        phoneNumber: phoneChanged ? newPhone : null,
      );
      if (!mounted) return;
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(challenge: challenge),
        ),
      );
      if (verified == true && mounted) {
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث بيانات التواصل بنجاح.')),
          );
        }
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر طلب تغيير بيانات التواصل.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _verificationStatus(String label, bool verified) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        verified ? Icons.verified_outlined : Icons.warning_amber_outlined,
        color: verified ? Colors.green : Theme.of(context).colorScheme.error,
      ),
      title: Text(label),
      subtitle: Text(verified ? 'تم التحقق' : 'غير مؤكد'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معلومات الحساب'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _verificationStatus(
                          'البريد الإلكتروني: ${_user?.email ?? ''}',
                          _user?.emailVerified ?? false,
                        ),
                        _verificationStatus(
                          'رقم الهاتف: ${_user?.phoneNumber ?? 'غير مضاف'}',
                          _user?.phoneVerified ?? false,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني الجديد',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty || !email.contains('@')) {
                              return 'أدخل بريداً إلكترونياً صحيحاً';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف الجديد',
                            hintText: '+9639XXXXXXXX',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) {
                            final phone = (value ?? '').replaceAll(
                              RegExp(r'[\s().-]'),
                              '',
                            );
                            return RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(phone)
                                ? null
                                : 'أدخل رقم هاتف صحيحاً مع مفتاح الدولة';
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _saving ? null : _saveContactDetails,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('إرسال رموز التحقق'),
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
