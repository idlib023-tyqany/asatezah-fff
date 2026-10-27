import 'dart:io';

/// مساعد العلامة المائية والمعالجة المسبقة للملفات
class WatermarkHelper {
  /// توليد النص التلقائي للعلامة المائية الخاصة بالأستاذ
  static String generateWatermarkText({required String teacherName, required String phoneNumber}) {
    return 'حقوق الطبع محفوظة للأستاذ: $teacherName | هاتف: $phoneNumber';
  }

  /// التحقق من أن الملف المختار هو ملف PDF صالح للرفع
  static bool isValidPdf(String filePath) {
    final file = File(filePath);
    return file.existsSync() && filePath.toLowerCase().endsWith('.pdf');
  }
}
