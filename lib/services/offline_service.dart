import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/file_item.dart';
import 'api_service.dart';

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

  OfflineService._internal({ApiService? apiService}) : _api = apiService ?? ApiService();

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

      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'فشل التنزيل رمز الاستجابة: ${response.statusCode}',
          uri: Uri.parse(downloadUrl),
        );
      }

      final contentLength = response.contentLength;
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
      return OpenResult(type: ResultType.fileNotFound, message: 'الملف غير موجود على ذاكرة الجهاز');
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
          final path = map['localPath'] as String? ?? map['local_path'] as String?;
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
      final lastSegment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
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
