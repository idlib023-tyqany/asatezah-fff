import 'package:flutter/material.dart';

import 'teacher_file_details_model.dart';

class TeacherFileDetailsView extends StatelessWidget {
  const TeacherFileDetailsView({
    required this.file,
    required this.isFavorite,
    required this.onFavorite,
    required this.onReport,
    super.key,
  });

  final TeacherFileModel file;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الملف التعليمي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'إبلاغ',
            onPressed: onReport,
          ),
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
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 54,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'معاينة أول صفحة من الملف',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المعرف الفريد: ${file.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              file.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'النوع: ${file.fileType} • الحجم: ${file.fileSize}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('قراءة فورية (Online)'),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('جاري فتح الملف للقراءة المباشرة...'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download_for_offline_rounded),
                    label: const Text('حفظ بدون إنترنت'),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تم تحميل الملف وتخزينه ليعمل بدون إنترنت',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton.filledTonal(
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite ? Colors.red : null,
                  ),
                  tooltip: 'إضافة للمفضلة',
                  onPressed: onFavorite,
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'مشاركة ذكية',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم نسخ رابط الملف: ID=${file.id}')),
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.star_border_rounded),
                  tooltip: 'تقييم بالنجوم',
                  onPressed: () {},
                ),
              ],
            ),
            const Divider(height: 28),
            const Text(
              'إحصائيات الملف بالمنصة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  'المشاهدات',
                  file.viewsCount.toString(),
                  Icons.visibility_outlined,
                ),
                _StatItem(
                  'التحميلات',
                  file.downloadsCount.toString(),
                  Icons.download_outlined,
                ),
                _StatItem(
                  'المفضلة',
                  file.favoritesCount.toString(),
                  Icons.favorite_border,
                ),
                _StatItem(
                  'التقييم',
                  '${file.ratingAvg} ★',
                  Icons.star_rate_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
