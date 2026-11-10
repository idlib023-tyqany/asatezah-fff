import 'package:asatezah/core/network/api_service.dart';

import 'folder_explorer_model.dart';
import '../teacher_file_details/teacher_file_details_model.dart';

class FolderExplorerService {
  FolderExplorerService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<FolderListing> loadRoot() async {
    final response = await _api.get('/folders/root');
    return FolderListing.fromJson(response);
  }

  Future<FolderListing> loadFolder(int folderId) async {
    if (folderId < 1) {
      throw ArgumentError.value(folderId, 'folderId', 'معرّف المجلد غير صالح.');
    }

    final response = await _api.get('/folders/$folderId');
    return FolderListing.fromJson(response);
  }
}

class FolderListing {
  const FolderListing({
    required this.title,
    required this.subfolders,
    required this.files,
  });

  final String title;
  final List<FolderModel> subfolders;
  final List<TeacherFileModel> files;

  factory FolderListing.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final rawFolders = json['subfolders'];
    final rawFiles = json['files'];
    if (current is! Map || rawFolders is! List || rawFiles is! List) {
      throw const FormatException('استجابة محتويات المجلد غير صالحة.');
    }

    return FolderListing(
      title: current['name'] as String? ?? '',
      subfolders: rawFolders.map((item) {
        if (item is! Map) {
          throw const FormatException('بيانات أحد المجلدات غير صالحة.');
        }
        return FolderModel.fromJson(Map<String, dynamic>.from(item));
      }).toList(),
      files: rawFiles.map((item) {
        if (item is! Map) {
          throw const FormatException('بيانات أحد الملفات غير صالحة.');
        }
        return TeacherFileModel.fromJson(Map<String, dynamic>.from(item));
      }).toList(),
    );
  }
}
