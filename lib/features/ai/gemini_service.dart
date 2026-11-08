import '../../core/network/api_service.dart';

class GeminiService {
  final ApiService _api = ApiService();

  Future<String?> generateText(String prompt) async {
    try {
      final response = await _api.post('/ai/assistant', body: {
        'prompt': prompt.trim(),
      });
      return response['answer'] as String?;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'عذراً، حدث خطأ أثناء الاتصال بالمساعد الذكي.';
    }
  }
}
