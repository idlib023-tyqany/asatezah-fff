import 'package:asatezah/core/network/api_service.dart';

class TeacherAiService {
  TeacherAiService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<String> ask(String prompt, String mode) async {
    final response = await _api.post(
      '/ai/assist',
      body: {'prompt': prompt, 'mode': mode},
    );
    final result = response['result'];
    if (result is! String || result.isEmpty) {
      throw const FormatException('استجابة المساعد الذكي غير صالحة.');
    }
    return result;
  }
}
