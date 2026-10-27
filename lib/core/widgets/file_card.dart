import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';
import './file_type_icon.dart';

/// FileCard: بطاقة عرض الملفات الأكاديمية والتعليمية بشكل شبكي أو قوائم
class FileCard extends StatelessWidget {
  final FileItem file;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;

  const FileCard({super.key, required this.file, required this.onTap, this.onFavorite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accentFor(file.filename, theme.colorScheme.primary);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // منطقة الغلاف والأيقونة
              Stack(
                children: [
                  Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Center(
                      child: FileTypeIcon(filename: file.filename, color: Colors.white, size: 44),
                    ),
                  ),

                  // زر إضافة / إزالة المفضلة (متوافق مع اتجاه العربية RTL)
                  if (onFavorite != null)
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      top: 4,
                      end: 4,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.25),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          onPressed: onFavorite,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                          tooltip: file.isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                          icon: Icon(
                            file.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: file.isFavorite ? Colors.redAccent : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                  // تقييم المستخدم الخاص
                  if (file.myRating != null)
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      top: 8,
                      start: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              '${file.myRating}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // شارة الملف المحفوظ أوفلاين
                  if (file.localPath != null && file.localPath!.isNotEmpty)
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      bottom: 8,
                      start: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.offline_pin, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),

              // التفاصيل والمعلومات النصية
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      file.category?.name ?? 'غير مصنّف',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      file.fileSizeFormatted,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey.shade400 : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // الإحصائيات (التنزيلات، المشاهدات، التقييم)
                    Row(
                      children: [
                        Icon(
                          Icons.download_outlined,
                          size: 14,
                          color: isDark ? Colors.grey.shade400 : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${file.stats.downloadsCount}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: isDark ? Colors.grey.shade400 : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${file.stats.viewsCount}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : AppTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          file.stats.avgRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey.shade300 : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// تحديد لون التمييز بناءً على امتداد اسم الملف
  Color _accentFor(String filename, Color defaultPrimary) {
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'pdf':
        return const Color(0xFFDC2626);
      case 'doc':
      case 'docx':
        return const Color(0xFF2563EB);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF16A34A);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFEA580C);
      case 'zip':
      case 'rar':
      case '7z':
        return const Color(0xFF7C3AED);
      case 'mp4':
      case 'mkv':
      case 'avi':
        return const Color(0xFFD97706);
      case 'mp3':
      case 'wav':
        return const Color(0xFF059669);
      default:
        return defaultPrimary;
    }
  }
}
