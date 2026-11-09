import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';

class FileDetailsScreen extends StatefulWidget {
  final FileModel file;

  const FileDetailsScreen({super.key, required this.file});

  @override
  State<FileDetailsScreen> createState() => _FileDetailsScreenState();
}

class _FileDetailsScreenState extends State<FileDetailsScreen> {
  bool _isFavorite = false;

  void _toggleFav() async {
    final status = await ApiService.toggleFavorite(widget.file.id);
    if (!mounted) return;
    setState(() => _isFavorite = status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isFavorite ? 'تمت إضافة الملف لمفضلاتك ❤️' : 'تم حذف الملف من المفضلة')),
    );
  }

  void _showReportDialog() {
    final reasonController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('إبلاغ عن هذا الملف للإدارة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'سبب البلاغ (مثل: خطأ علمي، تلف...)')),
            const SizedBox(height: 8),
            TextField(controller: messageController, decoration: const InputDecoration(labelText: 'الملاحظة التفصيلية')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (reasonController.text.isNotEmpty) {
                final reason = reasonController.text;
                final message = messageController.text;
                Navigator.of(dialogCtx).pop();
                await ApiService.reportFile(widget.file.id, reason, message);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال بلاغك للإدارة بنجاح')));
              }
            },
            child: const Text('إرسال البلاغ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الملف التعليمي'),
        actions: [
          IconButton(icon: const Icon(Icons.flag_outlined), tooltip: 'إبلاغ', onPressed: _showReportDialog),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf_rounded, size: 54, color: colorScheme.primary),
                  const SizedBox(height: 8),
                  Text('معاينة أول صفحة من الملف', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('المعرف الفريد: ${widget.file.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.file.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('النوع: ${widget.file.fileType} • الحجم: ${widget.file.fileSize}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
            const Divider(height: 28),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('قراءة فورية (Online)'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري فتح الملف للقراءة المباشرة...')));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download_for_offline_rounded),
                    label: const Text('حفظ بدون إنترنت'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحميل الملف وتخزينه ليعمل بدون إنترنت')));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton.filledTonal(
                  icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _isFavorite ? Colors.red : null),
                  tooltip: 'إضافة للمفضلة',
                  onPressed: _toggleFav,
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'مشاركة ذكية',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ رابط الملف: ID=${widget.file.id}')));
                  },
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.star_border_rounded),
                  tooltip: 'تقييم بالنجوم',
                  onPressed: () {},
                ),
              ],
            ),
            const Divider(height: 28),

            const Text('إحصائيات الملف بالمنصة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('المشاهدات', widget.file.viewsCount.toString(), Icons.visibility_outlined),
                _buildStatItem('التحميلات', widget.file.downloadsCount.toString(), Icons.download_outlined),
                _buildStatItem('المفضلة', widget.file.favoritesCount.toString(), Icons.favorite_border),
                _buildStatItem('التقييم', '${widget.file.ratingAvg} ★', Icons.star_rate_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
