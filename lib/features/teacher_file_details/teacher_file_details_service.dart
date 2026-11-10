import 'package:asatezah/core/network/api_service.dart';

class TeacherFileDetailsService {
  TeacherFileDetailsService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<bool> toggleFavorite(String fileId) async {
    final response = await _api.post('/files/$fileId/favorite');
    return response['is_favorite'] == true || response['is_favorite'] == 1;
  }

  Future<void> reportFile(String fileId, String reason, String message) async {
    await _api.post(
      '/files/$fileId/report',
      body: {'reason': reason, 'message': message},
    );
  }
}
