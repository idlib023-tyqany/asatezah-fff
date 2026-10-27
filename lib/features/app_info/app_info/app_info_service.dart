import 'package:asatezah/core/network/api_service.dart';
import './app_info_model.dart';

class AppInfoService {
  static final AppInfoService _instance = AppInfoService._internal();
  factory AppInfoService() => _instance;
  AppInfoService._internal();

  final ApiService _api = ApiService();
  AppInfo? _cachedInfo;

  Future<AppInfo> fetchInfo({bool forceRefresh = false}) async {
    if (_cachedInfo != null && !forceRefresh) {
      return _cachedInfo!;
    }

    try {
      final result = await _api.get('/info');
      _cachedInfo = AppInfo.fromJson(result);
      return _cachedInfo!;
    } catch (_) {
      if (_cachedInfo != null) {
        return _cachedInfo!;
      }
      rethrow;
    }
  }

  void clearCache() {
    _cachedInfo = null;
  }
}
