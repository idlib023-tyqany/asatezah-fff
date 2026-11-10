import 'package:flutter/material.dart';

import 'teacher_tools_model.dart';

class TeacherToolsView extends StatelessWidget {
  const TeacherToolsView({
    required this.isLoading,
    required this.error,
    required this.timetable,
    required this.progress,
    required this.notes,
    required this.onAddTimetable,
    required this.onUpdateProgress,
    required this.onAddNote,
    required this.onRetry,
    super.key,
  });

  final bool isLoading;
  final String? error;
  final List<TimetableSlot> timetable;
  final List<ClassProgress> progress;
  final List<ClassNote> notes;
  final VoidCallback onAddTimetable;
  final VoidCallback onUpdateProgress;
  final VoidCallback onAddNote;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مكتب وأدوات الأستاذ'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_month_rounded), text: 'جدول الحصص'),
              Tab(icon: Icon(Icons.bookmark_added_rounded), text: 'أين توقفت؟'),
              Tab(icon: Icon(Icons.sticky_note_2_rounded), text: 'مفكرة الصف'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: onRetry,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              )
            : TabBarView(
                children: [
                  _TimetableTab(
                    slots: timetable,
                    colorScheme: colorScheme,
                    onAdd: onAddTimetable,
                  ),
                  _ProgressTab(
                    progress: progress,
                    colorScheme: colorScheme,
                    onAdd: onUpdateProgress,
                  ),
                  _NotesTab(notes: notes, onAdd: onAddNote),
                ],
              ),
      ),
    );
  }
}

class _TimetableTab extends StatelessWidget {
  const _TimetableTab({
    required this.slots,
    required this.colorScheme,
    required this.onAdd,
  });

  final List<TimetableSlot> slots;
  final ColorScheme colorScheme;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('إضافة حصة'),
      ),
      body: slots.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.event_note_rounded,
                    size: 54,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text('لم تضف حصصاً بعد في جدولك الأسبوعي'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onAdd,
                    child: const Text('إضافة أول حصة'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: slots.length,
              itemBuilder: (context, index) {
                final item = slots[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.school_rounded,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      '${item.subjectName} • ${item.gradeName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      '${item.startTime} إلى ${item.endTime} • ${item.section} • تنبيه قبل ${item.reminderMinutes} د',
                    ),
                    trailing: const Icon(
                      Icons.alarm_on_rounded,
                      color: Colors.teal,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab({
    required this.progress,
    required this.colorScheme,
    required this.onAdd,
  });

  final List<ClassProgress> progress;
  final ColorScheme colorScheme;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.edit_location_alt_rounded),
        label: const Text('تحديث التوقف'),
      ),
      body: progress.isEmpty
          ? const Center(
              child: Text('اضغط على الزر بالأسفل لتحديد أين توقفت مع كل شعبة'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: progress.length,
              itemBuilder: (context, index) {
                final item = progress[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.gradeName} - ${item.section}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Chip(
                              label: Text(
                                'آخر نقطة توقف',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'الدرس: ${item.lastTopic}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item.pageNumber != null)
                          Text(
                            'الصفحة: ${item.pageNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.notes, required this.onAdd});

  final List<ClassNote> notes;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.note_add_rounded),
        label: const Text('ملاحظة جديدة'),
      ),
      body: notes.isEmpty
          ? const Center(child: Text('لا توجد ملاحظات صفية مسجلة حالياً'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final item = notes[index];
                return Card(
                  color: Colors.amber.shade50,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.push_pin_rounded,
                      color: Colors.amber,
                    ),
                    title: Text(
                      item.content,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      '${item.gradeName} • ${item.section}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
