import 'package:flutter/material.dart';

import 'teacher_tools_model.dart';
import 'teacher_tools_service.dart';
import 'teacher_tools_view.dart';

class TeacherToolsWidget extends StatefulWidget {
  const TeacherToolsWidget({super.key});

  @override
  State<TeacherToolsWidget> createState() => _TeacherToolsWidgetState();
}

class _TeacherToolsWidgetState extends State<TeacherToolsWidget> {
  final TeacherToolsService _service = TeacherToolsService();
  List<TimetableSlot> _timetable = const [];
  List<ClassProgress> _progress = const [];
  List<ClassNote> _notes = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final values = await Future.wait([
        _service.getTimetable(),
        _service.getProgress(),
        _service.getNotes(),
      ]);
      if (!mounted) return;
      setState(() {
        _timetable = values[0] as List<TimetableSlot>;
        _progress = values[1] as List<ClassProgress>;
        _notes = values[2] as List<ClassNote>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل أدوات الأستاذ: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddTimetableDialog() async {
    final start = TextEditingController(text: '08:00');
    final end = TextEditingController(text: '08:45');
    final section = TextEditingController(text: 'شعبة أ');
    final classroom = TextEditingController(text: 'القاعة 4');
    var day = 'sunday';

    final values = await showDialog<(String, String, String, String, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة حصة دراسية جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: day,
                  decoration: const InputDecoration(labelText: 'اليوم'),
                  items: const [
                    DropdownMenuItem(value: 'sunday', child: Text('الأحد')),
                    DropdownMenuItem(value: 'monday', child: Text('الاثنين')),
                    DropdownMenuItem(value: 'tuesday', child: Text('الثلاثاء')),
                    DropdownMenuItem(
                      value: 'wednesday',
                      child: Text('الأربعاء'),
                    ),
                    DropdownMenuItem(value: 'thursday', child: Text('الخميس')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => day = value);
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: start,
                        decoration: const InputDecoration(
                          labelText: 'وقت البداية',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: end,
                        decoration: const InputDecoration(
                          labelText: 'وقت النهاية',
                        ),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: section,
                  decoration: const InputDecoration(labelText: 'الشعبة'),
                ),
                TextField(
                  controller: classroom,
                  decoration: const InputDecoration(
                    labelText: 'القاعة / المدرسة',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop((day, start.text, end.text, section.text, classroom.text)),
              child: const Text('حفظ الحصة والتنبيه'),
            ),
          ],
        ),
      ),
    );
    start.dispose();
    end.dispose();
    section.dispose();
    classroom.dispose();
    if (values == null) return;

    await _runAction(
      () => _service.addTimetableSlot(
        day: values.$1,
        startTime: values.$2,
        endTime: values.$3,
        section: values.$4,
        classroom: values.$5,
      ),
    );
  }

  Future<void> _showUpdateProgressDialog() async {
    final topic = TextEditingController();
    final page = TextEditingController();
    final section = TextEditingController(text: 'شعبة أ');
    final values = await showDialog<(String, String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('أين توقفت مع الشعبة؟'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: section,
              decoration: const InputDecoration(
                labelText: 'الشعبة (مثل: أ، ب)',
              ),
            ),
            TextField(
              controller: topic,
              decoration: const InputDecoration(
                labelText: 'آخر عنوان درس شرحته',
              ),
            ),
            TextField(
              controller: page,
              decoration: const InputDecoration(labelText: 'رقم الصفحة'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (topic.text.trim().isNotEmpty) {
                Navigator.of(dialogContext)
                    .pop((section.text, topic.text, page.text));
              }
            },
            child: const Text('حفظ نقطة التوقف'),
          ),
        ],
      ),
    );
    topic.dispose();
    page.dispose();
    section.dispose();
    if (values == null) return;

    await _runAction(
      () => _service.updateProgress(
        section: values.$1,
        topic: values.$2,
        page: values.$3,
      ),
    );
  }

  Future<void> _showAddNoteDialog() async {
    final note = TextEditingController();
    final section = TextEditingController(text: 'شعبة أ');
    final values = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ملاحظة سريعة للصف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: section,
              decoration: const InputDecoration(labelText: 'الشعبة'),
            ),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'اكتب ملاحظتك للحصة القادمة...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (note.text.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop((section.text, note.text));
              }
            },
            child: const Text('حفظ الملاحظة'),
          ),
        ],
      ),
    );
    note.dispose();
    section.dispose();
    if (values == null) return;

    await _runAction(
      () => _service.addNote(section: values.$1, content: values.$2),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
      await _loadAllData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تعذّر حفظ البيانات: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TeacherToolsView(
      isLoading: _isLoading,
      error: _error,
      timetable: _timetable,
      progress: _progress,
      notes: _notes,
      onAddTimetable: _showAddTimetableDialog,
      onUpdateProgress: _showUpdateProgressDialog,
      onAddNote: _showAddNoteDialog,
      onRetry: _loadAllData,
    );
  }
}
