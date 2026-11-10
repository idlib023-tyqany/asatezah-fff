class TimetableSlot {
  const TimetableSlot({
    required this.subjectName,
    required this.gradeName,
    required this.startTime,
    required this.endTime,
    required this.section,
    required this.reminderMinutes,
  });

  final String subjectName;
  final String gradeName;
  final String startTime;
  final String endTime;
  final String section;
  final int reminderMinutes;

  factory TimetableSlot.fromJson(Map<String, dynamic> json) => TimetableSlot(
    subjectName: json['subject_name']?.toString() ?? '',
    gradeName: json['grade_name']?.toString() ?? '',
    startTime: json['start_time']?.toString() ?? '',
    endTime: json['end_time']?.toString() ?? '',
    section: json['section']?.toString() ?? '',
    reminderMinutes:
        int.tryParse(json['reminder_minutes']?.toString() ?? '') ?? 15,
  );
}

class ClassProgress {
  const ClassProgress({
    required this.gradeName,
    required this.section,
    required this.lastTopic,
    this.pageNumber,
  });

  final String gradeName;
  final String section;
  final String lastTopic;
  final String? pageNumber;

  factory ClassProgress.fromJson(Map<String, dynamic> json) => ClassProgress(
    gradeName: json['grade_name']?.toString() ?? '',
    section: json['section']?.toString() ?? '',
    lastTopic: json['last_topic']?.toString() ?? '',
    pageNumber: json['page_number']?.toString(),
  );
}

class ClassNote {
  const ClassNote({
    required this.gradeName,
    required this.section,
    required this.content,
  });

  final String gradeName;
  final String section;
  final String content;

  factory ClassNote.fromJson(Map<String, dynamic> json) => ClassNote(
    gradeName: json['grade_name']?.toString() ?? '',
    section: json['section']?.toString() ?? '',
    content: json['note_content']?.toString() ?? '',
  );
}
