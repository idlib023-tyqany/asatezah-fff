class FolderModel {
  const FolderModel({
    required this.id,
    required this.name,
    required this.isRoot,
    this.gradeId,
  });

  final int id;
  final String name;
  final bool isRoot;
  final int? gradeId;

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse(json['id']?.toString() ?? '');
    if (id == null || id < 1) {
      throw const FormatException('معرّف المجلد غير صالح.');
    }

    return FolderModel(
      id: id,
      name: json['name'] as String? ?? '',
      isRoot: json['is_root'] == 1 || json['is_root'] == true,
      gradeId: int.tryParse(json['grade_id']?.toString() ?? ''),
    );
  }
}
