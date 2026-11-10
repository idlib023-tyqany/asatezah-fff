import 'dart:async';

import 'package:flutter/material.dart';
import 'package:asatezah/core/network/api_service.dart';
import 'package:asatezah/main.dart';

import 'otp_model.dart';
import 'otp_service.dart';
import 'otp_view.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    required this.challenge,
    this.previewMode = false,
    super.key,
  });

  final Map<String, dynamic> challenge;
  final bool previewMode;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _emailCode = TextEditingController();
  final _phoneCode = TextEditingController();
  final OtpService _service = OtpService();
  late OtpChallenge _challenge;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _challenge = OtpChallenge.fromJson(widget.challenge);
  }

  @override
  void dispose() {
    _emailCode.dispose();
    _phoneCode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_challenge.channels.contains('email') &&
        _emailCode.text.trim().length != 6) {
      setState(() => _error = 'أدخل رمز البريد المكوّن من 6 أرقام.');
      return;
    }
    if (_challenge.channels.contains('phone') &&
        _phoneCode.text.trim().length != 6) {
      setState(() => _error = 'أدخل رمز الهاتف المكوّن من 6 أرقام.');
      return;
    }
    if (widget.previewMode) {
      setState(() => _error = 'وضع المعاينة: لم يتم التحقق من الرموز.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _service.verify(
        _challenge,
        emailCode: _emailCode.text.trim(),
        phoneCode: _phoneCode.text.trim(),
      );
      if (_challenge.purpose == 'contact_change') {
        if (mounted) Navigator.of(context).pop(true);
      } else {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const RootScreen()),
            (route) => false,
          );
        }
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on TimeoutException {
      if (mounted) setState(() => _error = 'انتهت مهلة الاتصال. حاول مجدداً.');
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر التحقق. حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (widget.previewMode) {
      setState(() {
        _error = 'وضع المعاينة: لم يتم إرسال أي رموز.';
        _emailCode.clear();
        _phoneCode.clear();
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _challenge = await _service.resend(_challenge);
      _emailCode.clear();
      _phoneCode.clear();
      if (mounted) setState(() {});
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر إعادة إرسال الرموز.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OtpView(
      challenge: _challenge,
      emailCode: _emailCode,
      phoneCode: _phoneCode,
      isLoading: _loading,
      error: _error,
      onVerify: _verify,
      onResend: _resend,
    );
  }
}
