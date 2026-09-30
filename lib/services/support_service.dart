import 'dart:io';

import '../models/paginated_list.dart';
import '../models/support.dart';
import 'api_service.dart';

/// SupportService: إدارة محادثات وشكاوى الدعم الفني بين المستخدم والفريق
class SupportService {
  final ApiService _api;

  // نمط Singleton اختياري يدعم تمرير Mock ApiService للاختبارات
  static final SupportService _instance = SupportService._internal();

  factory SupportService({ApiService? apiService}) {
    if (apiService != null) {
      return SupportService._internal(apiService: apiService);
    }
    return _instance;
  }

  SupportService._internal({ApiService? apiService}) : _api = apiService ?? ApiService();

  /// جلب قائمة المحادثات الخاصة بالمستخدم (صندوق الوارد)
  Future<List<Conversation>> fetchInbox() async {
    final result = await _api.get('/support');

    final data = result['data'] as List<dynamic>? ?? (result is List ? result : []);

    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map((e) {
          try {
            return Conversation.fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<Conversation>()
        .toList();
  }

  /// إنشاء محادثة جديدة مع فريق الدعم
  Future<Conversation> startConversation(String subject) async {
    final trimmedSubject = subject.trim();
    if (trimmedSubject.isEmpty) {
      throw ArgumentError('عنوان المحادثة لا يمكن أن يكون فارغاً');
    }

    final result = await _api.post('/support', body: {'subject': trimmedSubject});

    return _parseModel<Conversation>(result, (json) => Conversation.fromJson(json));
  }

  /// جلب رسائل محادثة معينة مع دعم الترقيم (Pagination)
  Future<PaginatedList<Message>> fetchMessages(
    int conversationId, {
    int page = 1,
    int perPage = 30,
  }) async {
    if (conversationId <= 0) {
      throw ArgumentError('معرف المحادثة غير صالح');
    }
    if (page < 1 || perPage < 1) {
      throw ArgumentError('قيم الترقيم (page / perPage) يجب أن تكون أكبر من 0');
    }

    final result = await _api.get(
      '/support/$conversationId/messages',
      queryParams: {'page': page.toString(), 'per_page': perPage.toString()},
    );

    return PaginatedList<Message>.fromJson(result, (json) => Message.fromJson(json));
  }

  /// دالة مساعدة سريعة لجلب الرسائل في كقائمة مباشرة (List  Message) بدون Pagination
  /// لاستخدامها المباشر في الشاشات البسيطة
  Future<List<Message>> fetchMessagesList(int conversationId) async {
    final page = await fetchMessages(conversationId);
    return page.items;
  }

  /// إرسال رسالة نصية داخل المحادثة
  Future<Message> sendText(int conversationId, String body) async {
    if (conversationId <= 0) {
      throw ArgumentError('معرف المحادثة غير صالح');
    }

    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      throw ArgumentError('محتوى الرسالة لا يمكن أن يكون فارغاً');
    }

    final result = await _api.post(
      '/support/$conversationId/messages',
      body: {'body': trimmedBody},
    );

    return _parseModel<Message>(result, (json) => Message.fromJson(json));
  }

  /// إرسال صورة مع نص اختياري داخل المحادثة
  Future<Message> sendImage(int conversationId, String imagePath, {String? body}) async {
    if (conversationId <= 0) {
      throw ArgumentError('معرف المحادثة غير صالح');
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw ArgumentError('ملف الصورة المرفق غير موجود على ذاكرة الجهاز');
    }

    final fields = <String, String>{
      if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
    };

    final result = await _api.uploadFile(
      '/support/$conversationId/messages',
      imagePath,
      fields: fields,
      fileField: 'image',
    );

    return _parseModel<Message>(result, (json) => Message.fromJson(json));
  }

  /// إغلاق المحادثة
  Future<void> closeConversation(int conversationId) async {
    if (conversationId <= 0) {
      throw ArgumentError('معرف المحادثة غير صالح');
    }
    await _api.post('/support/$conversationId/close');
  }

  // --- Helpers ---

  /// معالجة صحة الاستجابة وتحويلها للنموذج المطلوب
  T _parseModel<T>(dynamic result, T Function(Map<String, dynamic>) fromJson) {
    if (result is! Map<String, dynamic>) {
      throw const FormatException('استجابة غير صالحة من الخادم');
    }

    final data = result['data'] is Map<String, dynamic>
        ? result['data'] as Map<String, dynamic>
        : result;

    return fromJson(data);
  }
}
