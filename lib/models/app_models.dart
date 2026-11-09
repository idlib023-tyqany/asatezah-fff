class FolderModel {
  final int id;
  final String name;
  final bool isRoot;
  final int? gradeId;

  FolderModel({required this.id, required this.name, required this.isRoot, this.gradeId});

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'],
      name: json['name'] ?? '',
      isRoot: json['is_root'] == 1 || json['is_root'] == true,
      gradeId: json['grade_id'],
    );
  }
}

class FileModel {
  final String id; // رقم الـ 20 خانة
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

  FileModel({
    required this.id,
    required this.folderId,
    required this.name,
    required this.fileType,
    required this.filePath,
    required this.fileSize,
    this.thumbnailUrl,
    required this.viewsCount,
    required this.downloadsCount,
    required this.favoritesCount,
    required this.ratingAvg,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'].toString(),
      folderId: json['folder_id'] ?? 0,
      name: json['name'] ?? '',
      fileType: json['file_type'] ?? 'pdf',
      filePath: json['file_path'] ?? '',
      fileSize: json['file_size'] ?? '0 MB',
      thumbnailUrl: json['thumbnail_url'],
      viewsCount: json['views_count'] ?? 0,
      downloadsCount: json['downloads_count'] ?? 0,
      favoritesCount: json['favorites_count'] ?? 0,
      ratingAvg: double.tryParse(json['rating_avg']?.toString() ?? '0') ?? 0.0,
    );
  }
}
