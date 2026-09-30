import 'api_service.dart';

/// AdminService: جميع العمليات الخاصة بلوحة التحكم والإدارة
/// توفر واجهة موحدة مع نهايات الخدمة `/admin/*`
class AdminService {
  final ApiService _api;

  static AdminService? _instance;

  /// factory يضمن نمط Singleton مع إمكانية حقن Mock ApiService للاختبارات
  factory AdminService({ApiService? apiService}) {
    if (apiService != null) {
      return AdminService._internal(apiService);
    }
    _instance ??= AdminService._internal(ApiService());
    return _instance!;
  }

  AdminService._internal(this._api);

  // ==========================================
  // إدارة المستخدمين (Users)
  // ==========================================

  Future<Map<String, dynamic>> fetchUsers({String? q, int page = 1, int perPage = 30}) async {
    final result = await _api.get(
      '/admin/users',
      queryParams: {
        'page': '$page',
        'per_page': '$perPage',
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      },
    );
    return result;
  }

  Future<void> setContribution(int userId, bool canContribute) async {
    await _api.post('/admin/users/$userId/contribution', body: {'can_contribute': canContribute});
  }

  Future<void> deleteUser(int userId) async {
    await _api.delete('/admin/users/$userId');
  }

  // ==========================================
  // إدارة الملفات والمراجعة والسلة (Files & Review)
  // ==========================================

  Future<Map<String, dynamic>> fetchFiles({
    String status = 'pending',
    String? q,
    int page = 1,
    int perPage = 30,
  }) async {
    final result = await _api.get(
      '/admin/files',
      queryParams: {
        'status': status,
        'page': '$page',
        'per_page': '$perPage',
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      },
    );
    return result;
  }

  Future<void> approveFile(int id) async => await _api.post('/admin/files/$id/approve');

  Future<void> rejectFile(int id) async => await _api.post('/admin/files/$id/reject');

  Future<void> reopenFile(int id) async => await _api.post('/admin/files/$id/reopen');

  Future<void> moveFile(int id, {int? categoryId, int? materialId}) async {
    final Map<String, dynamic> body = {};
    if (categoryId != null) body['category_id'] = categoryId;
    if (materialId != null) body['material_id'] = materialId;

    await _api.put('/admin/files/$id/move', body: body);
  }

  Future<void> trashFile(int id) async => await _api.delete('/admin/files/$id');

  Future<void> restoreFile(int id) async => await _api.post('/admin/files/$id/restore');

  Future<void> forceDeleteFile(int id) async => await _api.delete('/admin/files/$id/force');

  Future<void> emptyTrash() async => await _api.post('/admin/trash/empty');

  /// الإحصائيات العامة
  Future<Map<String, dynamic>> statistics() async {
    final result = await _api.get('/admin/statistics');
    return result;
  }

  Future<Map<String, dynamic>> fetchStatistics() async => statistics();

  // ==========================================
  // إدارة التصنيفات والمواد (Categories & Materials)
  // ==========================================

  Future<List<dynamic>> fetchCategories() async {
    final r = await _api.get('/admin/categories');
    return r['data'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> createCategory(String name) async {
    final r = await _api.post('/admin/categories', body: {'name': name.trim()});
    return r;
  }

  Future<void> updateCategory(int id, String name) async {
    await _api.put('/admin/categories/$id', body: {'name': name.trim()});
  }

  Future<void> deleteCategory(int id) async {
    await _api.delete('/admin/categories/$id');
  }

  Future<Map<String, dynamic>> createMaterial(String name, {int? categoryId}) async {
    final Map<String, dynamic> body = {'name': name.trim(), 'category_id': categoryId};

    final r = await _api.post('/admin/materials', body: body);
    return r;
  }

  Future<List<dynamic>> fetchMaterials() async {
    final r = await _api.get('/admin/materials');
    return r['data'] as List<dynamic>? ?? [];
  }

  Future<void> updateMaterial(int id, String name) async {
    await _api.put('/admin/materials/$id', body: {'name': name.trim()});
  }

  Future<void> deleteMaterial(int id) async {
    await _api.delete('/admin/materials/$id');
  }

  // ==========================================
  // إدارة البلاغات (Reports)
  // ==========================================

  Future<List<dynamic>> fetchReports({String status = 'open'}) async {
    final r = await _api.get('/admin/reports', queryParams: {'status': status});
    return r['data'] as List<dynamic>? ?? [];
  }

  Future<void> resolveReport(int id) async => await _api.patch('/admin/reports/$id/resolve');

  Future<void> dismissReport(int id) async => await _api.patch('/admin/reports/$id/dismiss');

  // ==========================================
  // إدارة الدعم الفني (Support)
  // ==========================================

  Future<List<dynamic>> fetchSupportConversations() async {
    final r = await _api.get('/admin/support');
    return r['data'] as List<dynamic>? ?? [];
  }

  Future<void> claimSupportConversation(int conversationId) async {
    await _api.post('/admin/support/$conversationId/claim');
  }

  // ==========================================
  // الإشعارات الجماعية (Notifications)
  // ==========================================

  Future<void> sendToAll(String title, String body) async {
    await _api.post('/admin/notifications/all', body: {'title': title.trim(), 'body': body.trim()});
  }

  Future<void> sendToSpecialization(String specialization, String title, String body) async {
    await _api.post(
      '/admin/notifications/specialization',
      body: {'specialization': specialization.trim(), 'title': title.trim(), 'body': body.trim()},
    );
  }

  // ==========================================
  // الإعدادات والشعار (Settings)
  // ==========================================

  Future<Map<String, dynamic>> fetchSettings() async {
    final r = await _api.get('/admin/settings');
    return r;
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await _api.put('/admin/settings', body: settings);
  }

  Future<String> uploadLogo(String filePath) async {
    final r = await _api.uploadFile('/admin/settings/logo', filePath, fields: {});
    return r['logo_path'] as String? ?? '';
  }
}
