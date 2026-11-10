class TeacherFileModel {
  const TeacherFileModel({
    required this.id,
    required this.folderId,
    required this.name,
    required this.fileType,
    required this.filePath,
    required this.fileSize,
    this.thumbnailUrl,
    this.viewsCount = 0,
    this.downloadsCount = 0,
    this.favoritesCount = 0,
    this.ratingAvg = 0,
  });

  final String id;
  final int folderId;
  final String name;
  final String fileType;
  final String filePath;
  final String fileSize;
  final String? thumbnailUrl;
  final int viewsCount;
  final int downloadsCount;
  final int favoritesCount;
  final double ratingAvg;

  factory TeacherFileModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('معرّف الملف غير صالح.');
    }

    return TeacherFileModel(
      id: id,
      folderId: int.tryParse(json['folder_id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      fileType: json['file_type'] as String? ?? 'pdf',
      filePath: json['file_path'] as String? ?? '',
      fileSize: json['file_size']?.toString() ?? '0 MB',
      thumbnailUrl: json['thumbnail_url'] as String?,
      viewsCount: int.tryParse(json['views_count']?.toString() ?? '') ?? 0,
      downloadsCount:
          int.tryParse(json['downloads_count']?.toString() ?? '') ?? 0,
      favoritesCount:
          int.tryParse(json['favorites_count']?.toString() ?? '') ?? 0,
      ratingAvg: double.tryParse(json['rating_avg']?.toString() ?? '') ?? 0,
    );
  }
}
