import 'package:google_generative_ai/google_generative_ai.dart';

import '../../core/network/api_config.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: ApiConfig.geminiApiKey);
  }
  Future<String?> generateText(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      // ignore: avoid_print
      print('Error calling Gemini API: $e');
      return 'عذراً، حدث خطأ أثناء الاتصال بالمساعد الذكي.';
    }
  }
}
