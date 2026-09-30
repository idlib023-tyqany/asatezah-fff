import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../../config/theme.dart';
import '../../models/file_item.dart';
import '../../services/offline_service.dart';
import '../file_detail/file_detail_screen.dart';

class OfflineFilesScreen extends StatefulWidget {
  const OfflineFilesScreen({super.key});

  @override
  State<OfflineFilesScreen> createState() => _OfflineFilesScreenState();
}

class _OfflineFilesScreenState extends State<OfflineFilesScreen> {
  final _offlineService = OfflineService();
  List<FileItem> _offlineFiles = [];
  bool _loading = true;
  int _totalSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadOfflineFiles();
  }

  Future<void> _loadOfflineFiles() async {
    setState(() => _loading = true);
    try {
      final files = await _offlineService.getOfflineFiles();
      final totalSize = await _offlineService.getTotalOfflineSizeInBytes();

      if (!mounted) return;
      setState(() {
        _offlineFiles = files;
        _totalSizeBytes = totalSize;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteFile(FileItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الملف من الجهاز'),
        content: Text('هل أنت تأكد من حذف "${item.title}" من التخزين المحلي؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _offlineService.removeOffline(item.id);
      if (!mounted) return;
      await _loadOfflineFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الملف محلياً بنجاح'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح كافة الملفات المحفوظة'),
        content: const Text(
          'سيؤدي هذا إلى حذف جميع الملفات المحملة من ذاكرة الجهاز. هل تريد الاستمرار؟',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('مسح الكل'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _offlineService.clearAllOfflineFiles();
      if (!mounted) return;
      await _loadOfflineFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إخلاء المساحة التخزينية بنجاح'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملفات المتاحة دون اتصال'),
        actions: [
          if (_offlineFiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'حذف جميع الملفات المحفوظة',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _offlineFiles.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Header Bar for Storage Stats
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: AppTheme.borderColor.withValues(alpha: 0.2),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sd_storage_outlined,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'المساحة المستهلكة: ${_formatSize(_totalSizeBytes)} (${_offlineFiles.length} ملف)',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _offlineFiles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final file = _offlineFiles[index];
                      return _buildOfflineCard(file);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOfflineCard(FileItem item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.insert_drive_file_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                item.category?.name ?? '',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              if (item.material?.name != null) ...[
                const Text(' • ', style: TextStyle(color: AppTheme.textSecondary)),
                Text(
                  item.material?.name ?? '',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.file_open_outlined),
              tooltip: 'فتح الملف',
              onPressed: () async {
                if (item.localPath != null) {
                  final res = await _offlineService.openOfflineFile(item.localPath!);
                  if (mounted) {
                    if (res.type.name != ResultType.done.name) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تعذر فتح الملف: ${res.message}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'حذف من الجهاز',
              onPressed: () => _deleteFile(item),
            ),
          ],
        ),
        onTap: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => FileDetailScreen(file: item)));
          if (mounted) {
            _loadOfflineFiles();
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.cloud_off_outlined, size: 70, color: AppTheme.borderColor),
          SizedBox(height: 16),
          Text(
            'لا توجد ملفات محفوظة دون اتصال',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'يمكنك حفظ أي ملف عبر فتح تفاصيل الملف واختيار "تنزيل للاستخدام دون اتصال".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
