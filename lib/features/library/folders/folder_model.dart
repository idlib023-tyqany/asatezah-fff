import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';

class FolderItem {
  final int id;
  final String name;
  final int? parentId;
  final int? categoryId;
  final int filesCount;

  const FolderItem({
    required this.id,
    required this.name,
    this.parentId,
    this.categoryId,
    this.filesCount = 0,
  });

  factory FolderItem.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse(json['id']?.toString() ?? '');
    final name = json['name'];
    if (id == null || id < 1 || name is! String || name.isEmpty) {
      throw const FormatException('بيانات المجلد غير صالحة.');
    }

    return FolderItem(
      id: id,
      name: name,
      parentId: int.tryParse(json['parent_id']?.toString() ?? ''),
      categoryId: int.tryParse(json['category_id']?.toString() ?? ''),
      filesCount: int.tryParse(json['files_count']?.toString() ?? '') ?? 0,
    );
  }
}

class FolderContents {
  final FolderItem folder;
  final List<FileItem> files;

  const FolderContents({required this.folder, required this.files});

  factory FolderContents.fromJson(Map<String, dynamic> json) {
    final folder = FolderItem.fromJson(json);
    final rawFiles = json['files'];
    if (rawFiles is! List) {
      throw const FormatException('قائمة ملفات المجلد غير صالحة.');
    }

    final files = rawFiles.map((item) {
      if (item is! Map) {
        throw const FormatException('بيانات أحد الملفات غير صالحة.');
      }

      return FileItem.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    return FolderContents(folder: folder, files: files);
  }
}
