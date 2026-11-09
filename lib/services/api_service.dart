import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<Map<String, dynamic>> getRootFolder() async {
    final res = await http.get(Uri.parse('$baseUrl/folders/root'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('فشل جلب المجلد الرئيسي');
  }

  static Future<Map<String, dynamic>> getFolder(int folderId) async {
    final res = await http.get(Uri.parse('$baseUrl/folders/$folderId'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('فشل جلب المجلد');
  }

  static Future<bool> toggleFavorite(String fileId) async {
    final res = await http.post(Uri.parse('$baseUrl/files/$fileId/favorite'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['is_favorite'] ?? false;
    }
    return false;
  }

  static Future<void> reportFile(String fileId, String reason, String message) async {
    await http.post(
      Uri.parse('$baseUrl/files/$fileId/report'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reason': reason, 'message': message}),
    );
  }

  // --- جدول الحصص ---
  static Future<List<dynamic>> getTimetable() async {
    final res = await http.get(Uri.parse('$baseUrl/timetable'));
    if (res.statusCode == 200) return jsonDecode(res.body)['data'] ?? [];
    return [];
  }

  static Future<void> addTimetableSlot(Map<String, dynamic> data) async {
    await http.post(
      Uri.parse('$baseUrl/timetable'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
  }

  // --- أين توقفت؟ ---
  static Future<List<dynamic>> getProgress() async {
    final res = await http.get(Uri.parse('$baseUrl/progress'));
    if (res.statusCode == 200) return jsonDecode(res.body)['data'] ?? [];
    return [];
  }

  static Future<void> updateProgress(int gradeId, String section, String topic, String page) async {
    await http.post(
      Uri.parse('$baseUrl/progress'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'grade_id': gradeId,
        'section': section,
        'last_topic': topic,
        'page_number': page,
      }),
    );
  }

  // --- المفكرة السريعة ---
  static Future<List<dynamic>> getNotes() async {
    final res = await http.get(Uri.parse('$baseUrl/notes'));
    if (res.statusCode == 200) return jsonDecode(res.body)['data'] ?? [];
    return [];
  }

  static Future<void> addNote(int gradeId, String section, String content) async {
    await http.post(
      Uri.parse('$baseUrl/notes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'grade_id': gradeId,
        'section': section,
        'note_content': content,
      }),
    );
  }

  // --- Gemini AI ---
  static Future<String> askGemini(String prompt, String mode, {int? folderId}) async {
    final Map<String, dynamic> body = {'prompt': prompt, 'mode': mode};
    if (folderId != null) body['folder_id'] = folderId;

    final res = await http.post(
      Uri.parse('$baseUrl/ai/assist'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['result'] ?? 'تم إتمام الطلب.';
    }
    throw Exception('فشل الاتصال بالمساعد الذكي');
  }
}
