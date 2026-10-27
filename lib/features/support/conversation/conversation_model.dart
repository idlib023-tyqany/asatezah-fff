

class Conversation {
  final int id;
  final String subject;
  final ConversationUser? user;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.subject,
    this.user,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      subject: json['subject'] as String? ?? '',
      user: json['user'] is Map<String, dynamic>
          ? ConversationUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'user': user?.toJson(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Conversation copyWith({
    int? id,
    String? subject,
    ConversationUser? user,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      user: user ?? this.user,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Conversation &&
        other.id == id &&
        other.subject == subject &&
        other.user == user &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(id, subject, user, status, createdAt, updatedAt);
}

class ConversationUser {
  final int id;
  final String name;

  const ConversationUser({required this.id, required this.name});

  factory ConversationUser.fromJson(Map<String, dynamic> json) {
    return ConversationUser(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  ConversationUser copyWith({int? id, String? name}) {
    return ConversationUser(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationUser && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}

class Message {
  final int id;
  final String? body;
  final String? imagePath;
  final ConversationUser? sender;
  final bool mine;
  final DateTime createdAt;

  const Message({
    required this.id,
    this.body,
    this.imagePath,
    this.sender,
    required this.mine,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      body: json['body'] as String?,
      imagePath: json['image_path'] as String?,
      sender: json['sender'] is Map<String, dynamic>
          ? ConversationUser.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      mine:
          json['mine'] == true ||
          json['mine'] == 1 ||
          json['mine']?.toString().toLowerCase() == 'true',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body,
      'image_path': imagePath,
      'sender': sender?.toJson(),
      'mine': mine,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Message copyWith({
    int? id,
    String? body,
    String? imagePath,
    ConversationUser? sender,
    bool? mine,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      body: body ?? this.body,
      imagePath: imagePath ?? this.imagePath,
      sender: sender ?? this.sender,
      mine: mine ?? this.mine,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.body == body &&
        other.imagePath == imagePath &&
        other.sender == sender &&
        other.mine == mine &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, body, imagePath, sender, mine, createdAt);
}
