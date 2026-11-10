import 'package:flutter/material.dart';

import 'teacher_file_details_model.dart';
import 'teacher_file_details_service.dart';
import 'teacher_file_details_view.dart';

class TeacherFileDetailsWidget extends StatefulWidget {
  const TeacherFileDetailsWidget({required this.file, super.key});

  final TeacherFileModel file;

  @override
  State<TeacherFileDetailsWidget> createState() =>
      _TeacherFileDetailsWidgetState();
}

class _TeacherFileDetailsWidgetState extends State<TeacherFileDetailsWidget> {
  final TeacherFileDetailsService _service = TeacherFileDetailsService();
  bool _isFavorite = false;

  Future<void> _toggleFavorite() async {
    try {
      final isFavorite = await _service.toggleFavorite(widget.file.id);
      if (!mounted) return;
      setState(() => _isFavorite = isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? 'تمت إضافة الملف لمفضلاتك ❤️'
                : 'تم حذف الملف من المفضلة',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تعذّر تحديث المفضلة: $error')));
    }
  }

  Future<void> _reportFile() async {
    final reasonController = TextEditingController();
    final messageController = TextEditingController();
    final report = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إبلاغ عن هذا الملف للإدارة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'سبب البلاغ (مثل: خطأ علمي، تلف...)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'الملاحظة التفصيلية',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop((
                  reasonController.text.trim(),
                  messageController.text.trim(),
                ));
              }
            },
            child: const Text('إرسال البلاغ'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    messageController.dispose();
    if (report == null) return;

    try {
      await _service.reportFile(widget.file.id, report.$1, report.$2);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال بلاغك للإدارة بنجاح')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تعذّر إرسال البلاغ: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TeacherFileDetailsView(
      file: widget.file,
      isFavorite: _isFavorite,
      onFavorite: _toggleFavorite,
      onReport: _reportFile,
    );
  }
}
