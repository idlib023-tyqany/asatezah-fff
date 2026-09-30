class FileStats {
  final int viewsCount;
  final int downloadsCount;
  final int favoritesCount;
  final double avgRating;
  final int ratingsCount;

  FileStats({
    required this.viewsCount,
    required this.downloadsCount,
    required this.favoritesCount,
    required this.avgRating,
    required this.ratingsCount,
  });

  factory FileStats.fromJson(Map<String, dynamic> json) {
    return FileStats(
      viewsCount: int.tryParse(json['views_count']?.toString() ?? '') ?? 0,
      downloadsCount: int.tryParse(json['downloads_count']?.toString() ?? '') ?? 0,
      favoritesCount: int.tryParse(json['favorites_count']?.toString() ?? '') ?? 0,
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
}
