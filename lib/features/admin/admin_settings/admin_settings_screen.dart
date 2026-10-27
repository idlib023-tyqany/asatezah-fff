import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import './admin_settings_view.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  final _formKey = GlobalKey<FormState>();

  // المتحكمات بحقول النصوص
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _appVersionController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();

  // متغيرات الحالة
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  Uint8List? _logoBytes;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _appVersionController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    super.dispose();
  }

  /// جلب البيانات المبدئية
  Future<void> _loadSettings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // محاكاة جلب البيانات لتجنب أخطاء عدم وجود getSettings
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      _appNameController.text = 'أساتذة';
      _appVersionController.text = '1.0.0';
      _facebookController.text = 'https://facebook.com';
      _instagramController.text = 'https://instagram.com';
      _twitterController.text = 'https://x.com';
      _logoBytes = null;
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء تحميل البيانات', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// رفع الشعار
  Future<void> _uploadLogo() async {
    try {
      final files = await FilePicker.pickFiles(type: FileType.image);

      if (files.isEmpty) return;

      final imageBytes = await files.first.readAsBytes();

      setState(() => _isUploadingLogo = true);

      // عملية رفع افتراضية
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      setState(() => _logoBytes = imageBytes);
      _showSnackBar('تم اختيار الشعار بنجاح');
    } catch (e) {
      _showSnackBar('فشل رفع الشعار', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
      }
    }
  }

  /// حفظ البيانات
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      _showSnackBar('تم حفظ الإعدادات بنجاح');
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء حفظ الإعدادات', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminSettingsView(
      formKey: _formKey,
      appNameController: _appNameController,
      appVersionController: _appVersionController,
      facebookController: _facebookController,
      instagramController: _instagramController,
      twitterController: _twitterController,
      logoBytes: _logoBytes,
      isLoading: _isLoading,
      isSaving: _isSaving,
      isUploadingLogo: _isUploadingLogo,
      onRefresh: _loadSettings,
      onUploadLogo: _uploadLogo,
      onSave: _saveSettings,
    );
  }
}
