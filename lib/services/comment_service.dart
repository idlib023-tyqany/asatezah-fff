import '../models/comment.dart';
import 'api_service.dart';

/// CommentService: إدارة عمليات التعليقات الخاصة بالملفات
class CommentService {
  final ApiService _api;

  // نمط Singleton اختياري يدعم تمرير Mock ApiService للاختبارات
  static final CommentService _instance = CommentService._internal();

  factory CommentService({ApiService? apiService}) {
    if (apiService != null) {
      return CommentService._internal(apiService: apiService);
    }
    return _instance;
  }

  CommentService._internal({ApiService? apiService}) : _api = apiService ?? ApiService();

  /// جلب التعليقات الخاصة بملف معين مع دعم الترقيم (Pagination)
  Future<List<Comment>> fetchComments(int fileId, {int page = 1, int perPage = 20}) async {
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
            // يمكن تسجيل الخطأ هنا عبر Logger
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

    final result = await _api.post('/files/$fileId/comments', body: {'body': trimmedBody});

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

    final result = await _api.put('/comments/$commentId', body: {'body': trimmedBody});

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
