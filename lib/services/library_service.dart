import '../models/catalog.dart';
import '../models/file_item.dart';
import '../models/paginated_list.dart';
import 'api_service.dart';

/// LibraryService: خدمة التعامل مع المكتبة والملفات
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

  LibraryService._internal({ApiService? apiService}) : _api = apiService ?? ApiService();

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
      if (categoryId != null && categoryId > 0) 'category_id': categoryId.toString(),
      if (materialId != null && materialId > 0) 'material_id': materialId.toString(),
      if (minRating != null && minRating >= 1) 'min_rating': minRating.toString(),
    };

    final result = await _api.get('/files', queryParams: params);

    return PaginatedList<FileItem>.fromJson(result, (json) => FileItem.fromJson(json));
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
            final fileJson = (e.containsKey('file') && e['file'] is Map<String, dynamic>)
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

    _cachedFilters = FilterCatalog(categories: categories, materials: materials);
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

    final body = <String, dynamic>{if (_isNotBlank(reason)) 'reason': reason!.trim()};

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
