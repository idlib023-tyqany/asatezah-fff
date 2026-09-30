class Comment {
  final int id;
  final String body;
  final CommentUser? user;
  final bool mine;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.body,
    this.user,
    required this.mine,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      // تحويل آمن للـ ID
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,

      body: json['body'] as String? ?? '',

      // التأكد من أن user عبارة عن Map قبل تحويله
      user: json['user'] is Map<String, dynamic>
          ? CommentUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,

      // معالجة القيم سواء كانت bool أو int (1/0) أو String ("true"/"1")
      mine:
          json['mine'] == true ||
          json['mine'] == 1 ||
          json['mine']?.toString().toLowerCase() == 'true',

      // تحليل آمن للتاريخ
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body,
      'user': user?.toJson(),
      'mine': mine,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CommentUser {
  final int id;
  final String name;

  CommentUser({required this.id, required this.name});

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
