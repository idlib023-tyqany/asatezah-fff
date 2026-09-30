import 'dart:io';

import 'api_service.dart';

/// UploadService: إدارة رفع الملفات للمراجعة قبل النشر
class UploadService {
  final ApiService _api;

  // نمط Singleton اختياري يدعم تمرير Mock ApiService للاختبارات
  static final UploadService _instance = UploadService._internal();

  factory UploadService({ApiService? apiService}) {
    if (apiService != null) {
      return UploadService._internal(apiService: apiService);
    }
    return _instance;
  }

  UploadService._internal({ApiService? apiService}) : _api = apiService ?? ApiService();

  /// رفع ملف جديد للمراجعة من قبل الإدارة
  ///
  /// يرجِع نتيجة استجابة السيرفر للتحقق من النجاح أو استلام بيانات الملف المرفوع.
  Future<Map<String, dynamic>> upload({
    required String filePath,
    required String title,
    String? description,
    int? categoryId,
    int? materialId,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('عنوان الملف لا يمكن أن يكون فارغاً');
    }

    if (categoryId != null && categoryId <= 0) {
      throw ArgumentError('معرف التصنيف غير صالح');
    }

    if (materialId != null && materialId <= 0) {
      throw ArgumentError('معرف المادة غير صالح');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('الملف المحدد غير موجود على الجهاز', filePath);
    }

    final fileSize = await file.length();
    if (fileSize == 0) {
      throw ArgumentError('لا يمكن رفع ملف فارغ (حجمه 0 بايت)');
    }

    final fields = <String, String>{
      'title': trimmedTitle,
      if (_isNotBlank(description)) 'description': description!.trim(),
      if (categoryId != null && categoryId > 0) 'category_id': categoryId.toString(),
      if (materialId != null && materialId > 0) 'material_id': materialId.toString(),
    };

    final result = await _api.uploadFile('/upload', filePath, fields: fields);

    return <String, dynamic>{'success': true, 'data': result};
  }

  // --- Helpers ---

  bool _isNotBlank(String? value) => value != null && value.trim().isNotEmpty;
}
