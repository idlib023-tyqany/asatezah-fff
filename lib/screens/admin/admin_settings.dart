import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../widgets/app_logo.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  final _admin = AdminService();
  final _formKey = GlobalKey<FormState>();

  final _appName = TextEditingController();
  final _appVersion = TextEditingController();
  final _telegram = TextEditingController();
  final _youtube = TextEditingController();
  final _facebook = TextEditingController();
  final _instagram = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _appName.dispose();
    _appVersion.dispose();
    _telegram.dispose();
    _youtube.dispose();
    _facebook.dispose();
    _instagram.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final s = await _admin.fetchSettings();
      if (!mounted) return;
      setState(() {
        _appName.text = s['app_name'] ?? '';
        _appVersion.text = s['app_version'] ?? '';
        _telegram.text = s['link_telegram'] ?? '';
        _youtube.text = s['link_youtube'] ?? '';
        _facebook.text = s['link_facebook'] ?? '';
        _instagram.text = s['link_instagram'] ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await _admin.updateSettings({
        'app_name': _appName.text.trim(),
        'app_version': _appVersion.text.trim(),
        'link_telegram': _telegram.text.trim(),
        'link_youtube': _youtube.text.trim(),
        'link_facebook': _facebook.text.trim(),
        'link_instagram': _instagram.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الإعدادات بنجاح'), backgroundColor: Colors.green),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذّر حفظ الإعدادات، يرجى المحاولة لاحقاً'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadLogo() async {
    // ✅ تم تحديث الاستدعاء إلى FilePicker.instance.pickFiles
    final FilePickerResult? result = await FilePicker.instance.pickFiles(
      type: FileType.image,
      withData: false,
    );

    if (result == null || result.files.isEmpty || result.files.first.path == null) {
      return;
    }

    final String filePath = result.files.first.path!;

    setState(() => _uploadingLogo = true);
    try {
      await _admin.uploadLogo(filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الشعار بنجاح'), backgroundColor: Colors.green),
        );
        setState(() {});
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذّر رفع الشعار، يرجى التحقق من الملف'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات التطبيق'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const AppLogo(size: 88),
                            const SizedBox(height: 8),
                            Text(
                              'شعار التطبيق الحالي',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _uploadingLogo ? null : _uploadLogo,
                              icon: _uploadingLogo
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload_file),
                              label: Text(_uploadingLogo ? 'جاري الرفع...' : 'تغيير الشعار'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'بيانات التطبيق الأساسية',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _appName,
                              decoration: const InputDecoration(
                                labelText: 'اسم التطبيق',
                                prefixIcon: Icon(Icons.app_shortcut_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty)
                                  ? 'يرجى إدخال اسم التطبيق'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _appVersion,
                              decoration: const InputDecoration(
                                labelText: 'رقم الإصدار (e.g. 1.0.0)',
                                prefixIcon: Icon(Icons.verified_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty)
                                  ? 'يرجى إدخال رقم الإصدار'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'روابط التواصل الاجتماعي',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _telegram,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'رابط قناة / حساب تيليغرام',
                                prefixIcon: Icon(Icons.send_rounded),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _youtube,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'رابط قناة يوتيوب',
                                prefixIcon: Icon(Icons.play_circle_fill_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _facebook,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'رابط صفحة فيسبوك',
                                prefixIcon: Icon(Icons.facebook),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _instagram,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'رابط حساب إنستغرام',
                                prefixIcon: Icon(Icons.camera_alt_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'جاري الحفظ...' : 'حفظ التغييرات'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
