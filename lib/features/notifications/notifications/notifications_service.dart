import 'package:asatezah/core/network/api_service.dart';
import 'package:asatezah/core/models/paginated_list.dart';
import 'notifications_model.dart';

/// NotificationService (NotificationRemoteDataSource): إدارة جلب وتحديد قراءة الإشعارات الخاصة بالمستخدم
class NotificationService {
  final ApiService _api;

  // نمط Singleton اختياري يدعم تمرير Mock ApiService للاختبارات
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService({ApiService? apiService}) {
    if (apiService != null) {
      return NotificationService._internal(apiService: apiService);
    }
    return _instance;
  }

  NotificationService._internal({ApiService? apiService}) : _api = apiService ?? ApiService();

  /// جلب الإشعارات الخاصة بالمستخدم مع دعم الترقيم (Pagination) وعدد غير المقروء
  Future<NotificationPage> fetchNotifications({int page = 1, int perPage = 20}) async {
    if (page < 1 || perPage < 1) {
      throw ArgumentError('قيم الترقيم (page / perPage) يجب أن تكون أكبر من 0');
    }

    final result = await _api.get(
      '/notifications',
      queryParams: {'page': page.toString(), 'per_page': perPage.toString()},
    );

    final paginatedList = PaginatedList<AppNotification>.fromJson(
      result,
      (json) => AppNotification.fromJson(json),
    );

    final unreadCount = int.tryParse('${result['unread_count']}') ?? 0;

    return NotificationPage(pageData: paginatedList, unreadCount: unreadCount);
  }

  /// جلب عدد الإشعارات غير المقروءة فقط (لاستخدامها في الـ Badge أو الشريط العلوي)
  Future<int> fetchUnreadCount() async {
    final result = await _api.get('/notifications/unread-count');
    return int.tryParse('${result['unread_count']}') ?? 0;
  }

  /// تعليم إشعار محدد بأنه تم قراءته
  Future<void> markRead(int userNotificationId) async {
    if (userNotificationId <= 0) {
      throw ArgumentError('معرف الإشعار غير صالح');
    }
    await _api.post('/notifications/$userNotificationId/read');
  }

  /// تعليم كافة الإشعارات كمقروءة
  Future<void> markAllRead() async {
    await _api.post('/notifications/read-all');
  }
}

/// نموذج يمثل نتيجة استعلام صفحة الإشعارات مع عدد غير المقروء
class NotificationPage {
  final PaginatedList<AppNotification> pageData;
  final int unreadCount;

  const NotificationPage({required this.pageData, required this.unreadCount});

  List<AppNotification> get notifications => pageData.items;
  int get currentPage => pageData.currentPage;
  int get totalPages => pageData.totalPages;
  bool get hasMore => pageData.hasNext;
}
