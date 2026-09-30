import 'dart:convert';

class CatalogItem {
  final int id;
  final String name;
  final String slug;
  final String? categoryName;

  const CatalogItem({required this.id, required this.name, required this.slug, this.categoryName});

  bool get isValid => id > 0 && name.trim().isNotEmpty;
  bool get isInvalid => !isValid;

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? json['category'] as String?,
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

  CatalogItem copyWith({int? id, String? name, String? slug, String? categoryName}) {
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
