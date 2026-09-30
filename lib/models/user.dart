class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool canContribute;
  final String? specialization;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.canContribute,
    this.specialization,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // تحويل آمن للـ ID
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,

      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',

      // معالجة مرنة للقيمة المنطقية (bool, int, String)
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

  // دالة لتسهيل تعديل بيانات الملف الشخصي محلياً
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
}
