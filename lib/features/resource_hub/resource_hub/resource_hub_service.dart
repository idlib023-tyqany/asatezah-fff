import 'package:asatezah/core/network/api_service.dart';
import 'package:asatezah/core/models/paginated_list.dart';

import 'dart:convert';
import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

import 'resource_hub_model.dart';

/// CommentService (CommentRemoteDataSource): إدارة عمليات التعليقات الخاصة بالملفات
class CommentService {
  final ApiService _api;

  CommentService({ApiService? apiService}) : _api = apiService ?? ApiService();

  /// جلب التعليقات الخاصة بملف معين مع دعم الترقيم (Pagination)
  Future<List<Comment>> fetchComments(
    int fileId, {
    int page = 1,
    int perPage = 20,
  }) async {
    if (fileId <= 0) {
      throw ArgumentError('معرف الملف غير صالح');
    }
    if (page < 1 || perPage < 1) {
      throw ArgumentError('قيم الترقيم (page / perPage) يجب أن تكون أكبر من 0');
    }

    final result = await _api.get(
      '/files/$fileId/comments',
      queryParams: {'page': page.toString(), 'per_page': perPage.toString()},
    );

    final List<dynamic> data = result['data'] as List<dynamic>? ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((e) {
          try {
            return Comment.fromJson(e);
          } catch (error) {
            return null;
          }
        })
        .whereType<Comment>()
        .toList();
  }

  /// إضافة تعليق جديد على ملف
  Future<Comment> addComment(int fileId, String body) async {
    if (fileId <= 0) {
      throw ArgumentError('معرف الملف غير صالح');
    }

    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      throw ArgumentError('لا يمكن إرسال تعليق فارغ');
    }

    final result = await _api.post(
      '/files/$fileId/comments',
      body: {'body': trimmedBody},
    );

    return _parseCommentResponse(result);
  }

  /// تعديل تعليق سابق
  Future<Comment> updateComment(int commentId, String body) async {
    if (commentId <= 0) {
      throw ArgumentError('معرف التعليق غير صالح');
    }

    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      throw ArgumentError('لا يمكن تعديل التعليق إلى نص فارغ');
    }

    final result = await _api.put(
      '/comments/$commentId',
      body: {'body': trimmedBody},
    );

    return _parseCommentResponse(result);
  }

  /// حذف تعليق
  Future<void> deleteComment(int commentId) async {
    if (commentId <= 0) {
      throw ArgumentError('معرف التعليق غير صالح');
    }

    await _api.delete('/comments/$commentId');
  }

  // --- Helpers ---

  /// معالجة استجابة الـ API واستخراج بيانات التعليق منها بشكل آمن
  Comment _parseCommentResponse(dynamic result) {
    if (result is! Map<String, dynamic>) {
      throw const FormatException('استجابة غير صالحة من الخادم');
    }

    final commentData = result['data'] is Map<String, dynamic>
        ? result['data'] as Map<String, dynamic>
        : result;

    return Comment.fromJson(commentData);
  }
}

/// LibraryService (LibraryRemoteDataSource): خدمة التعامل مع المكتبة والملفات
/// تشمل جلب الملفات، البحث والتصفية، المفضلة، التقييم، والبلاغات.
class LibraryService {
  final ApiService _api;

  static LibraryService? _instance;

  /// مصنع يدعم نمط Singleton وبنفس الوقت يتيح التمرير الصريح لـ Mock ApiService عند الاختبارات
  factory LibraryService({ApiService? apiService}) {
    if (apiService != null) {
      return LibraryService._internal(apiService: apiService);
    }
    _instance ??= LibraryService._internal();
    return _instance!;
  }

  LibraryService._internal({ApiService? apiService})
    : _api = apiService ?? ApiService();

  /// إعادة تعيين الـ Singleton (تُستخدم أساساً عند كتابة unit tests)
  static void resetInstance() {
    _instance = null;
  }

  // ذاكرة مؤقتة لكتالوج الفلاتر (التصنيفات والمواد)
  FilterCatalog? _cachedFilters;

  /// جلب الملفات المنشورة بناءً على الترقيم والبحث والفلاتر
  Future<PaginatedList<FileItem>> fetchFiles({
    int page = 1,
    int perPage = 20,
    String? sort,
    String? query,
    int? categoryId,
    int? materialId,
    int? minRating,
  }) async {
    if (page < 1 || perPage < 1) {
      throw ArgumentError('قيم الترقيم (page / perPage) يجب أن تكون أكبر من 0');
    }

    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (_isNotBlank(sort)) 'sort': sort!.trim(),
      if (_isNotBlank(query)) 'q': query!.trim(),
      if (categoryId != null && categoryId > 0)
        'category_id': categoryId.toString(),
      if (materialId != null && materialId > 0)
        'material_id': materialId.toString(),
      if (minRating != null && minRating >= 1)
        'min_rating': minRating.toString(),
    };

    final result = await _api.get('/files', queryParams: params);

    return PaginatedList<FileItem>.fromJson(
      result,
      (json) => FileItem.fromJson(json),
    );
  }

  /// جلب تفاصيل ملف محدد
  Future<FileItem> fetchFileDetail(int id) async {
    if (id <= 0) {
      throw ArgumentError('معرف الملف غير صالح');
    }

    final result = await _api.get('/files/$id');

    final data = result['data'] is Map<String, dynamic>
        ? result['data'] as Map<String, dynamic>
        : result;

    return FileItem.fromJson(data);
  }

  /// جلب قائمة الملفات المفضلة للمستخدم الحالي
  Future<List<FileItem>> fetchFavorites() async {
    final result = await _api.get('/favorites');

    List<dynamic> listData = [];
    if (result is List) {
      listData = [result];
    } else {
      listData = result['data'] as List<dynamic>? ?? [];
    }

    return listData
        .whereType<Map<String, dynamic>>()
        .map((e) {
          try {
            // معالجة حالة ما إذا كان كائن المفضلة يحتوي على الملف بداخل مفتاح 'file' أو مباشرة
            final fileJson =
                (e.containsKey('file') && e['file'] is Map<String, dynamic>)
                ? e['file'] as Map<String, dynamic>
                : e;
            return FileItem.fromJson(fileJson);
          } catch (_) {
            return null;
          }
        })
        .whereType<FileItem>()
        .toList();
  }

  /// جلب كتالوج التصنيفات والمواد لاستخدامها في التصفية
  Future<FilterCatalog> fetchFilters({bool forceRefresh = false}) async {
    if (_cachedFilters != null && !forceRefresh) {
      return _cachedFilters!;
    }

    final result = await _api.get('/filters');

    final categoriesData = result['categories'] as List<dynamic>? ?? [];
    final materialsData = result['materials'] as List<dynamic>? ?? [];

    final categories = categoriesData
        .whereType<Map<String, dynamic>>()
        .map((e) {
          try {
            return CatalogItem.fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<CatalogItem>()
        .toList();

    final materials = materialsData
        .whereType<Map<String, dynamic>>()
        .map((e) {
          try {
            return CatalogItem.fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<CatalogItem>()
        .toList();

    _cachedFilters = FilterCatalog(
      categories: categories,
      materials: materials,
    );
    return _cachedFilters!;
  }

  /// تبديل حالة المفضلة لملف (Toggle)
  Future<void> toggleFavorite(int fileId) async {
    if (fileId <= 0) throw ArgumentError('معرف الملف غير صالح');
    await _api.post('/favorites/$fileId/toggle');
  }

  /// إضافة ملف للمفضلة
  Future<void> addFavorite(int fileId) async {
    if (fileId <= 0) throw ArgumentError('معرف الملف غير صالح');
    await _api.post('/favorites/$fileId');
  }

  /// إزالة ملف من المفضلة
  Future<void> removeFavorite(int fileId) async {
    if (fileId <= 0) throw ArgumentError('معرف الملف غير صالح');
    await _api.delete('/favorites/$fileId');
  }

  /// تقييم ملف (من 1 إلى 5)
  Future<Map<String, dynamic>> rate(int fileId, int value) async {
    if (fileId <= 0) throw ArgumentError('معرف الملف غير صالح');
    if (value < 1 || value > 5) {
      throw ArgumentError('يجب أن يكون التقييم بين 1 و 5');
    }

    final result = await _api.post('/ratings/$fileId', body: {'value': value});
    return result;
  }

  /// الإبلاغ عن ملف
  Future<void> reportFile(int fileId, String? reason) async {
    if (fileId <= 0) throw ArgumentError('معرف الملف غير صالح');

    final body = <String, dynamic>{
      if (_isNotBlank(reason)) 'reason': reason!.trim(),
    };

    await _api.post('/reports/$fileId', body: body);
  }

  /// تفريغ كاش الفلاتر
  void clearFilterCache() {
    _cachedFilters = null;
  }

  // --- Helpers ---

  bool _isNotBlank(String? value) => value != null && value.trim().isNotEmpty;
}

/// نماذج البيانات المساعدة
class FilterCatalog {
  final List<CatalogItem> categories;
  final List<CatalogItem> materials;

  const FilterCatalog({required this.categories, required this.materials});
}

/// OfflineService: إدارة تنزيل وحفظ وتصفح الملفات أوفلاين بدون إنترنت
class OfflineService {
  final ApiService _api;

  static final OfflineService _instance = OfflineService._internal();

  factory OfflineService({ApiService? apiService}) {
    if (apiService != null) {
      return OfflineService._internal(apiService: apiService);
    }
    return _instance;
  }

  OfflineService._internal({ApiService? apiService})
    : _api = apiService ?? ApiService();

  static const String _keyOfflineFiles = 'offline_files';

  /// الحصول على المجلد المخصص للملفات المفرغة أوفلاين
  Future<Directory> _offlineDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${dir.path}/offline');
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }
    return offlineDir;
  }

  /// تنزيل الملف وحفظه محلياً للاستخدام بدون إنترنت مع دعم متابعة نسبة التقدم (Progress)
  Future<File> saveForOffline({
    required FileItem fileItem,
    required String downloadUrl,
    void Function(int count, int total)? onProgress,
  }) async {
    final dir = await _offlineDir();

    // استخراج امتداد الملف بطريقة أكثر أماناً
    final extension = _extractExtension(downloadUrl);
    final file = File('${dir.path}/${fileItem.id}.$extension');

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(downloadUrl));

      // إضافة التوكن الخاص بالمستخدم إذا وُجد
      final token = _api.token;
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }

      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'فشل التنزيل رمز الاستجابة: ${response.statusCode}',
          uri: Uri.parse(downloadUrl),
        );
      }

      final contentLength = response.contentLength;
      // ignore: deprecated_export_use
      final builder = BytesBuilder();
      int downloadedBytes = 0;

      await for (final chunk in response) {
        builder.add(chunk);
        downloadedBytes += chunk.length;
        if (onProgress != null && contentLength > 0) {
          onProgress(downloadedBytes, contentLength);
        }
      }

      final bytes = builder.takeBytes();
      await file.writeAsBytes(bytes, flush: true);

      // تحديث كائن الملف وتخزينه في التفضيلات المحلية
      final updatedItem = fileItem.copyWith(localPath: file.path);
      await _saveFileItemToPrefs(updatedItem);

      return file;
    } catch (e) {
      // تنظيف بقايا الملف غير المكتمل
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  /// جلب قائمة جميع الملفات المحفوظة أوفلاين والموجودة فعلياً في ذاكرة الجهاز
  Future<List<FileItem>> getOfflineFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_keyOfflineFiles) ?? [];

    final List<FileItem> validFiles = [];
    final List<String> updatedSavedList = [];

    for (final jsonStr in saved) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final item = FileItem.fromJson(map);

        if (item.localPath != null && await File(item.localPath!).exists()) {
          validFiles.add(item);
          updatedSavedList.add(jsonStr);
        }
      } catch (_) {
        // تجاهل الأسطر التالفة
      }
    }

    // تنظيف السجلات التالفة أو الملفات المحذوفة يدوياً من النظام
    if (saved.length != updatedSavedList.length) {
      await prefs.setStringList(_keyOfflineFiles, updatedSavedList);
    }

    return validFiles;
  }

  /// التحقق مما إذا كان ملف محدد متوفراً أوفلاين
  Future<bool> isAvailableOffline(int fileId) async {
    if (fileId <= 0) return false;
    final files = await getOfflineFiles();
    return files.any((f) => f.id == fileId);
  }

  /// فتح الملف المحفوظ محلياً باستخدام التطبيقات المتاحة على الجهاز
  Future<OpenResult> openOfflineFile(String path) async {
    if (path.isEmpty || !await File(path).exists()) {
      return OpenResult(
        type: ResultType.fileNotFound,
        message: 'الملف غير موجود على ذاكرة الجهاز',
      );
    }
    return await OpenFilex.open(path);
  }

  /// حذف ملف محدد من التخزين المحلّي بالسجل والذاكرة
  Future<void> removeOffline(int fileId) async {
    if (fileId <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_keyOfflineFiles) ?? [];
    final remainingList = <String>[];

    for (final jsonStr in saved) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final itemId = map['id'] as int?;

        if (itemId == fileId) {
          final path =
              map['localPath'] as String? ?? map['local_path'] as String?;
          if (path != null) {
            final f = File(path);
            if (await f.exists()) {
              await f.delete();
            }
          }
        } else {
          remainingList.add(jsonStr);
        }
      } catch (_) {
        // تجاهل الاستثناءات في المعالجة الفردية
      }
    }

    await prefs.setStringList(_keyOfflineFiles, remainingList);
  }

  /// مسح كافة الملفات المحفوظة أوفلاين
  Future<void> clearAllOfflineFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final dir = await _offlineDir();

    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
      await dir.create(recursive: true);
    }

    await prefs.remove(_keyOfflineFiles);
  }

  /// حساب إجمالي المساحة المستهلكة بواسطة كافة الملفات المحفوظة أوفلاين (بالبايت)
  Future<int> getTotalOfflineSizeInBytes() async {
    final files = await getOfflineFiles();
    int totalBytes = 0;

    for (final f in files) {
      if (f.localPath != null) {
        final file = File(f.localPath!);
        if (await file.exists()) {
          totalBytes += await file.length();
        }
      }
    }

    return totalBytes;
  }

  // --- Helper Methods ---

  /// استخراج امتداد الملف بطريقة آمنة
  String _extractExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final lastSegment = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : '';
      if (lastSegment.contains('.')) {
        final ext = lastSegment.split('.').last.toLowerCase();
        if (ext.length <= 4) return ext; // امتدادات قياسية مثل pdf, docx, epub
      }
    } catch (_) {}
    return 'pdf'; // افتراضي
  }

  /// حفظ أو تحديث كائن FileItem في SharedPreferences
  Future<void> _saveFileItemToPrefs(FileItem fileItem) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_keyOfflineFiles) ?? [];

    saved.removeWhere((jsonStr) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return map['id'] == fileItem.id;
      } catch (_) {
        return false;
      }
    });

    saved.add(jsonEncode(fileItem.toJson()));
    await prefs.setStringList(_keyOfflineFiles, saved);
  }
}

class ResourcePickerService {
  Future<List<PlatformFile>?> pickResources({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    final List<PlatformFile> files;
    if (allowMultiple) {
      files = await FilePicker.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
      );
    } else {
      final file = await FilePicker.pickFile(
        type: type,
        allowedExtensions: allowedExtensions,
      );
      files = file == null ? [] : [file];
    }

    return files.isEmpty ? null : files;
  }
}

/// UploadService (UploadRemoteDataSource): إدارة رفع الملفات للمراجعة قبل النشر
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

  UploadService._internal({ApiService? apiService})
    : _api = apiService ?? ApiService();

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
      if (categoryId != null && categoryId > 0)
        'category_id': categoryId.toString(),
      if (materialId != null && materialId > 0)
        'material_id': materialId.toString(),
    };

    final result = await _api.uploadFile('/upload', filePath, fields: fields);

    return <String, dynamic>{'success': true, 'data': result};
  }

  // --- Helpers ---

  bool _isNotBlank(String? value) => value != null && value.trim().isNotEmpty;
}
