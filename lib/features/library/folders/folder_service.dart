import 'package:asatezah/core/network/api_service.dart';

import 'folder_model.dart';

class FolderService {
  final ApiService _api;

  FolderService({ApiService? apiService}) : _api = apiService ?? ApiService();

  Future<List<FolderItem>> fetchFolders() async {
    final response = await _api.get('/folders');
    final rawFolders = response['data'];
    if (rawFolders is! List) {
      throw const FormatException('استجابة قائمة المجلدات غير صالحة.');
    }

    return rawFolders.map((item) {
      if (item is! Map) {
        throw const FormatException('بيانات أحد المجلدات غير صالحة.');
      }

      return FolderItem.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  Future<FolderContents> fetchFolder(int folderId) async {
    if (folderId < 1) {
      throw ArgumentError.value(
        folderId,
        'folderId',
        'معرف المجلد يجب أن يكون موجباً.',
      );
    }

    final response = await _api.get('/folders/$folderId');
    final data = response['data'];
    if (data is! Map) {
      throw const FormatException('استجابة بيانات المجلد غير صالحة.');
    }

    return FolderContents.fromJson(Map<String, dynamic>.from(data));
  }
}
