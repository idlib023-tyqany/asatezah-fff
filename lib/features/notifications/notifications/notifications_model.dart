

class AppNotification {
  final int id;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      read:
          json['read'] == true ||
          json['read'] == 1 ||
          json['read']?.toString().toLowerCase() == 'true',
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.read == read &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, title, body, read, createdAt);
}
