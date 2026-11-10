import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p; // لاستخراج اسم الملف بشكل آمن
import 'package:path_provider/path_provider.dart';

import './offline_files_view.dart';

class OfflineFilesScreen extends StatefulWidget {
  const OfflineFilesScreen({super.key});

  @override
  State<OfflineFilesScreen> createState() => _OfflineFilesScreenState();
}

class _OfflineFilesScreenState extends State<OfflineFilesScreen> {
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfflineFiles();
  }

  Future<void> _loadOfflineFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();

      // استخدام القراءة اللاتزامية لتجنب تجميد الواجهة
      final List<FileSystemEntity> entities = await dir.list().toList();

      final supportedExtensions = ['.pdf', '.docx', '.png', '.jpg', '.jpeg'];

      if (!mounted) return;

      setState(() {
        _files = entities.where((e) {
          final ext = p.extension(e.path).toLowerCase();
          return supportedExtensions.contains(ext);
        }).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openFile(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تعذّر فتح الملف: ${result.message}')));
    }
  }

  // حوار تأكيد الحذف
  Future<void> _confirmAndDelete(FileSystemEntity file) async {
    final fileName = p.basename(file.path);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت تأكد من حذف "$fileName"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteFile(file);
    }
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    try {
      await file.delete();
      await _loadOfflineFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الملف المحفوظ'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء حذف الملف'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OfflineFilesView(
      files: _files,
      isLoading: _isLoading,
      onRefresh: _loadOfflineFiles,
      onOpenFile: _openFile,
      onDelete: _confirmAndDelete,
    );
  }
}
