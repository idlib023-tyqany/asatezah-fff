import 'dart:convert';

class CatalogItem {
  final int id;
  final String name;
  final String slug;
  final String? categoryName;

  const CatalogItem({
    required this.id,
    required this.name,
    required this.slug,
    this.categoryName,
  });

  bool get isValid => id > 0 && name.trim().isNotEmpty;
  bool get isInvalid => !isValid;

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      categoryName:
          json['category_name'] as String? ?? json['category'] as String?,
    );
  }

  factory CatalogItem.fromRawJson(String str) =>
      CatalogItem.fromJson(json.decode(str) as Map<String, dynamic>);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (categoryName != null) 'category_name': categoryName,
    };
  }

  String toRawJson() => json.encode(toJson());

  CatalogItem copyWith({
    int? id,
    String? name,
    String? slug,
    String? categoryName,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatalogItem &&
        other.id == id &&
        other.name == name &&
        other.slug == slug &&
        other.categoryName == categoryName;
  }

  @override
  int get hashCode => Object.hash(id, name, slug, categoryName);

  @override
  String toString() => 'CatalogItem(id: $id, name: "$name", slug: "$slug")';
}

class Comment {
  final int id;
  final String body;
  final CommentUser? user;
  final bool mine;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Comment({
    required this.id,
    required this.body,
    this.user,
    required this.mine,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      body: json['body'] as String? ?? '',
      user: json['user'] is Map<String, dynamic>
          ? CommentUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      mine:
          json['mine'] == true ||
          json['mine'] == 1 ||
          json['mine']?.toString().toLowerCase() == 'true',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
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

  Comment copyWith({
    int? id,
    String? body,
    CommentUser? user,
    bool? mine,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      body: body ?? this.body,
      user: user ?? this.user,
      mine: mine ?? this.mine,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CommentUser {
  final int id;
  final String name;

  const CommentUser({required this.id, required this.name});

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

class CategoryInfo {
  final int id;
  final String name;

  const CategoryInfo({required this.id, required this.name});

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  CategoryInfo copyWith({int? id, String? name}) {
    return CategoryInfo(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryInfo && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
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

  const FileItem({
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
      fileSize:
          int.tryParse(
            (json['file_size'] ?? json['raw_file_size'])?.toString() ?? '',
          ) ??
          0,
      category: json['category'] is Map<String, dynamic>
          ? CategoryInfo.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      material: json['material'] is Map<String, dynamic>
          ? CategoryInfo.fromJson(json['material'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String? ?? 'pending',
      stats: FileStats.fromJson(
        json['stats'] is Map<String, dynamic>
            ? json['stats'] as Map<String, dynamic>
            : {},
      ),
      isFavorite:
          json['is_favorite'] == true ||
          json['is_favorite'] == 1 ||
          json['is_favorite']?.toString().toLowerCase() == 'true',
      myRating: int.tryParse(json['my_rating']?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileItem &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.filename == filename &&
        other.mimeType == mimeType &&
        other.fileSize == fileSize &&
        other.category == category &&
        other.material == material &&
        other.status == status &&
        other.stats == stats &&
        other.isFavorite == isFavorite &&
        other.myRating == myRating &&
        other.createdAt == createdAt &&
        other.localPath == localPath;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    description,
    filename,
    mimeType,
    fileSize,
    category,
    material,
    status,
    stats,
    isFavorite,
    myRating,
    createdAt,
    localPath,
  ]);
}

class FileStats {
  final int viewsCount;
  final int downloadsCount;
  final int favoritesCount;
  final double avgRating;
  final int ratingsCount;

  const FileStats({
    required this.viewsCount,
    required this.downloadsCount,
    required this.favoritesCount,
    required this.avgRating,
    required this.ratingsCount,
  });

  factory FileStats.fromJson(Map<String, dynamic> json) {
    return FileStats(
      viewsCount: int.tryParse(json['views_count']?.toString() ?? '') ?? 0,
      downloadsCount:
          int.tryParse(json['downloads_count']?.toString() ?? '') ?? 0,
      favoritesCount:
          int.tryParse(json['favorites_count']?.toString() ?? '') ?? 0,
      avgRating: double.tryParse(json['avg_rating']?.toString() ?? '') ?? 0.0,
      ratingsCount: int.tryParse(json['ratings_count']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'views_count': viewsCount,
      'downloads_count': downloadsCount,
      'favorites_count': favoritesCount,
      'avg_rating': avgRating,
      'ratings_count': ratingsCount,
    };
  }

  FileStats copyWith({
    int? viewsCount,
    int? downloadsCount,
    int? favoritesCount,
    double? avgRating,
    int? ratingsCount,
  }) {
    return FileStats(
      viewsCount: viewsCount ?? this.viewsCount,
      downloadsCount: downloadsCount ?? this.downloadsCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      avgRating: avgRating ?? this.avgRating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileStats &&
        other.viewsCount == viewsCount &&
        other.downloadsCount == downloadsCount &&
        other.favoritesCount == favoritesCount &&
        other.avgRating == avgRating &&
        other.ratingsCount == ratingsCount;
  }

  @override
  int get hashCode => Object.hash(
    viewsCount,
    downloadsCount,
    favoritesCount,
    avgRating,
    ratingsCount,
  );
}

class ResourceItem {
  final String id;
  final String title;
  final String subject;
  final String teacherName;
  final String teacherPhone;
  final String pdfUrl;
  final double rating;
  final DateTime createdAt;

  const ResourceItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.teacherName,
    required this.teacherPhone,
    required this.pdfUrl,
    this.rating = 5.0,
    required this.createdAt,
  });
}
