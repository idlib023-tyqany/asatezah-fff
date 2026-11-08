import 'dart:io';
import 'package:flutter/material.dart';
import 'package:asatezah/core/network/api_config.dart';
import 'package:asatezah/core/offline/offline_service.dart';
import 'package:asatezah/features/auth/auth_service.dart';
import 'package:asatezah/features/auth/login/login_screen.dart';
import '../resource_hub/resource_hub_model.dart';
import 'file_detail_view.dart';

class FileDetailScreen extends StatefulWidget {
  const FileDetailScreen({required this.file, super.key});
  final FileItem file;

  @override
  State<FileDetailScreen> createState() => _FileDetailScreenState();
}

class _FileDetailScreenState extends State<FileDetailScreen> {
  late FileItem _file;
  bool _isDownloading = false;
  final OfflineService _offline = OfflineService();
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _file = widget.file;
  }

  String get _fileUrl => '${ApiConfig.baseUrl}/files/${_file.id}/download';

  Future<void> _downloadFile() async {
    // إذا لم يكن المستخدم مسجلاً، نعرض له تنبيهاً لتسجيل الدخول
    if (!_auth.isAuthenticated) {
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تسجيل الدخول مطلوب'),
          content: const Text('يرجى تسجيل الدخول أو إنشاء حساب لتتمكن من تحميل هذا الملف والاحتفاظ به.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      );

      if (shouldLogin == true && mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
      return;
    }

    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final base = await _offline.getDownloadsDirectory();
      final folder = Directory('${base.path}/asatezah_downloads');
      if (!folder.existsSync()) {
        folder.createSync(recursive: true);
      }
      final target = File('${folder.path}/${_file.filename}');
      await _offline.saveForOffline(fileItem: _file, downloadUrl: _fileUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحميل الملف وحفظه بنجاح')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر تحميل الملف، يرجى المحاولة لاحقاً')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FileDetailView(
      file: _file,
      isDownloading: _isDownloading,
      onDownload: _downloadFile,
      onToggleFavorite: () {},
      onRate: (_) {},
    );
  }
}
