

class SubjectModel {
  final int id;
  final String name;

  SubjectModel({required this.id, required this.name});

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(id: json['id'], name: json['name']);
  }
}

class GradeModel {
  final int id;
  final String name;
  final List<SubjectModel> subjects;

  GradeModel({required this.id, required this.name, required this.subjects});

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    return GradeModel(
      id: json['id'],
      name: json['name'],
      subjects:
          (json['subjects'] as List<dynamic>?)?.map((subject) => SubjectModel.fromJson(subject)).toList() ??
          [],
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool canContribute;
  final String? specialization;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.canContribute,
    this.specialization,
  });

  /// كائن افتراضي فارغ للمستقبل أو الحالات الابتدائية
  factory User.empty() {
    return const User(id: 0, name: '', email: '', role: 'guest', canContribute: false);
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      canContribute:
          json['can_contribute'] == true ||
          json['can_contribute'] == 1 ||
          json['can_contribute']?.toString().toLowerCase() == 'true',
      specialization: json['specialization'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'can_contribute': canContribute,
      'specialization': specialization,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    bool? canContribute,
    String? specialization,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      canContribute: canContribute ?? this.canContribute,
      specialization: specialization ?? this.specialization,
    );
  }

  bool get isAdmin => role == 'admin';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.role == role &&
        other.canContribute == canContribute &&
        other.specialization == specialization;
  }

  @override
  int get hashCode => Object.hash(id, name, email, role, canContribute, specialization);
}
