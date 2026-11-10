import 'package:asatezah/core/network/api_service.dart';

import 'teacher_tools_model.dart';

class TeacherToolsService {
  TeacherToolsService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<List<TimetableSlot>> getTimetable() async =>
      _loadList('/timetable', TimetableSlot.fromJson);

  Future<List<ClassProgress>> getProgress() async =>
      _loadList('/progress', ClassProgress.fromJson);

  Future<List<ClassNote>> getNotes() async =>
      _loadList('/notes', ClassNote.fromJson);

  Future<void> addTimetableSlot({
    required String day,
    required String startTime,
    required String endTime,
    required String section,
    required String classroom,
  }) async {
    await _api.post(
      '/timetable',
      body: {
        'day_of_week': day,
        'start_time': startTime,
        'end_time': endTime,
        'grade_id': 8,
        'subject_id': 1,
        'section': section,
        'classroom': classroom,
        'reminder_minutes': 15,
      },
    );
  }

  Future<void> updateProgress({
    required String section,
    required String topic,
    required String page,
  }) async {
    await _api.post(
      '/progress',
      body: {
        'grade_id': 8,
        'section': section,
        'last_topic': topic,
        'page_number': page,
      },
    );
  }

  Future<void> addNote({
    required String section,
    required String content,
  }) async {
    await _api.post(
      '/notes',
      body: {'grade_id': 8, 'section': section, 'note_content': content},
    );
  }

  Future<List<T>> _loadList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final response = await _api.get(endpoint);
    final data = response['data'];
    if (data is! List) {
      throw FormatException('استجابة $endpoint غير صالحة.');
    }

    return data.map((item) {
      if (item is! Map) {
        throw FormatException('بيانات $endpoint غير صالحة.');
      }
      return parse(Map<String, dynamic>.from(item));
    }).toList();
  }
}
