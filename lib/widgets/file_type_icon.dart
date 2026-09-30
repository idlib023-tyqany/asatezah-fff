import 'package:flutter/material.dart';

/// FileTypeIcon: تعرض أيقونة مخصصة بناءً على امتداد الملف مع خيار تخصيص اللون والحجم
class FileTypeIcon extends StatelessWidget {
  final String filename;
  final Color? color;
  final double size;

  const FileTypeIcon({super.key, required this.filename, this.color, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? Theme.of(context).iconTheme.color ?? Colors.grey;
    final ext = _getExtension(filename);
    final iconData = _getIconForExtension(ext);
    final label = _getSemanticLabel(ext);

    return Icon(iconData, color: defaultColor, size: size, semanticLabel: label);
  }

  /// استخراج امتداد الملف بخطوة واحدة وبشكل آمن
  String _getExtension(String name) {
    final lastDot = name.lastIndexOf('.');
    if (lastDot == -1 || lastDot == name.length - 1) return '';
    return name.substring(lastDot + 1).toLowerCase();
  }

  /// مطابقة امتداد الملف مع الأيقونة المناسبة
  IconData _getIconForExtension(String ext) {
    switch (ext) {
      // مستندات PDF
      case 'pdf':
        return Icons.picture_as_pdf;

      // مستندات نصية وورد
      case 'doc':
      case 'docx':
      case 'odt':
      case 'rtf':
        return Icons.description;

      // جداول بيانات
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;

      // العروض التقديمية
      case 'ppt':
      case 'pptx':
      case 'key':
        return Icons.slideshow;

      // الصور
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'svg':
        return Icons.image;

      // الفيديو
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return Icons.play_circle;

      // الصوتيات
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'm4a':
      case 'flac':
        return Icons.audiotrack;

      // الملفات المضغوطة
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip;

      // البرمجة والنصوص
      case 'txt':
      case 'json':
      case 'xml':
      case 'dart':
      case 'html':
      case 'css':
        return Icons.code;

      // افتراضي
      default:
        return Icons.insert_drive_file;
    }
  }

  /// إرجاع وصف نصي لضعاف البصر لقارئ الشاشة
  String _getSemanticLabel(String ext) {
    switch (ext) {
      case 'pdf':
        return 'ملف مستند PDF';
      case 'doc':
      case 'docx':
        return 'ملف مستند وورد';
      case 'xls':
      case 'xlsx':
        return 'ملف جدول بيانات إكسل';
      case 'ppt':
      case 'pptx':
        return 'ملف عرض تقديمي باوربوينت';
      case 'zip':
      case 'rar':
        return 'ملف أراشيف مضغوط';
      default:
        return 'ملف مستند';
    }
  }
}
