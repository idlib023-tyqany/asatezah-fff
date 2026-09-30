import 'file_stats.dart';

class CategoryInfo {
  final int id;
  final String name;

  CategoryInfo({required this.id, required this.name});

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class FileItem {
  final int id;
  final String title;
  final String? description;
  final String filename;
  final String? mimeType;
  final int fileSize;
  final CategoryInfo? category;
  final CategoryInfo? material;
  final String status;
  final FileStats stats;
  final bool isFavorite;
  final int? myRating;
  final DateTime createdAt;
  final String? localPath;

  FileItem({
    required this.id,
    required this.title,
    this.description,
    required this.filename,
    this.mimeType,
    required this.fileSize,
    this.category,
    this.material,
    required this.status,
    required this.stats,
    required this.isFavorite,
    this.myRating,
    required this.createdAt,
    this.localPath,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      filename: json['filename'] as String? ?? '',
      mimeType: json['mime_type'] as String?,
      fileSize: int.tryParse(json['file_size']?.toString() ?? '') ?? 0,
      category: json['category'] is Map<String, dynamic>
          ? CategoryInfo.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      material: json['material'] is Map<String, dynamic>
          ? CategoryInfo.fromJson(json['material'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String? ?? 'pending',
      stats: FileStats.fromJson(
        json['stats'] is Map<String, dynamic> ? json['stats'] as Map<String, dynamic> : {},
      ),
      isFavorite:
          json['is_favorite'] == true ||
          json['is_favorite'] == 1 ||
          json['is_favorite']?.toString().toLowerCase() == 'true',
      myRating: int.tryParse(json['my_rating']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      localPath: json['local_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'filename': filename,
      'mime_type': mimeType,
      'file_size': fileSize,
      'category': category?.toJson(),
      'material': material?.toJson(),
      'status': status,
      'stats': stats.toJson(),
      'is_favorite': isFavorite,
      'my_rating': myRating,
      'created_at': createdAt.toIso8601String(),
      'local_path': localPath,
    };
  }

  FileItem copyWith({
    int? id,
    String? title,
    String? description,
    String? filename,
    String? mimeType,
    int? fileSize,
    CategoryInfo? category,
    CategoryInfo? material,
    String? status,
    FileStats? stats,
    bool? isFavorite,
    int? myRating,
    DateTime? createdAt,
    String? localPath,
  }) {
    return FileItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      filename: filename ?? this.filename,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      category: category ?? this.category,
      material: material ?? this.material,
      status: status ?? this.status,
      stats: stats ?? this.stats,
      isFavorite: isFavorite ?? this.isFavorite,
      myRating: myRating ?? this.myRating,
      createdAt: createdAt ?? this.createdAt,
      localPath: localPath ?? this.localPath,
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1048576) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / 1048576).toStringAsFixed(1)} MB';
  }
}
