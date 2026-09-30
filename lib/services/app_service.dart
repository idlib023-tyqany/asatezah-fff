import '../models/app_info.dart';
import 'api_service.dart';

class AppService {
  static final AppService _instance = AppService._internal();
  factory AppService() => _instance;
  AppService._internal();

  final ApiService _api = ApiService();

  // ذاكرة مؤقتة للبيانات لتجنب الطلبات المكررة
  AppInfo? _cachedInfo;

  /// الحصول على معلومات التطبيق الأساسية
  /// [forceRefresh]: عند تفعيلها يتم تجاهل الكاش وجلب البيانات من السيرفر مجدداً
  Future<AppInfo> fetchInfo({bool forceRefresh = false}) async {
    if (_cachedInfo != null && !forceRefresh) {
      return _cachedInfo!;
    }

    try {
      final result = await _api.get('/info');
      _cachedInfo = AppInfo.fromJson(result);
      return _cachedInfo!;
    } catch (e) {
      // إعادة استدعاء الكاش السابق إن وجد عند حدوث خطأ في الاتصال
      if (_cachedInfo != null) {
        return _cachedInfo!;
      }
      rethrow;
    }
  }

  /// مسح الذاكرة المؤقتة لمعلومات التطبيق
  void clearCache() {
    _cachedInfo = null;
  }
}
