class AppNotification {
  final int id;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      // تحويل آمن للـ ID
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,

      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',

      // معالجة كافة أشكال حالة القراءة (bool, int, String)
      read:
          json['read'] == true ||
          json['read'] == 1 ||
          json['read']?.toString().toLowerCase() == 'true',

      // تحليل آمن للتاريخ
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // دالة لتسهيل تحديث حالة الإشعار إلى "مقروء" محلياً في الـ UI
  AppNotification copyWith({
    int? id,
    String? title,
    String? body,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
