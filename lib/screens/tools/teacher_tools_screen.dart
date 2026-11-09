import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TeacherToolsScreen extends StatefulWidget {
  const TeacherToolsScreen({super.key});

  @override
  State<TeacherToolsScreen> createState() => _TeacherToolsScreenState();
}

class _TeacherToolsScreenState extends State<TeacherToolsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _timetable = [];
  List<dynamic> _progressList = [];
  List<dynamic> _notesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final tt = await ApiService.getTimetable();
    final prog = await ApiService.getProgress();
    final notes = await ApiService.getNotes();
    if (!mounted) return;
    setState(() {
      _timetable = tt;
      _progressList = prog;
      _notesList = notes;
      _isLoading = false;
    });
  }

  void _showAddTimetableDialog() {
    final startCtrl = TextEditingController(text: '08:00');
    final endCtrl = TextEditingController(text: '08:45');
    final sectionCtrl = TextEditingController(text: 'شعبة أ');
    final roomCtrl = TextEditingController(text: 'القاعة 4');
    String selectedDay = 'sunday';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة حصة دراسية جديدة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedDay,
                decoration: const InputDecoration(labelText: 'اليوم'),
                items: const [
                  DropdownMenuItem(value: 'sunday', child: Text('الأحد')),
                  DropdownMenuItem(value: 'monday', child: Text('الاثنين')),
                  DropdownMenuItem(value: 'tuesday', child: Text('الثلاثاء')),
                  DropdownMenuItem(value: 'wednesday', child: Text('الأربعاء')),
                  DropdownMenuItem(value: 'thursday', child: Text('الخميس')),
                ],
                onChanged: (v) => selectedDay = v!,
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'وقت البداية'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'وقت النهاية'))),
                ],
              ),
              TextField(controller: sectionCtrl, decoration: const InputDecoration(labelText: 'الشعبة')),
              TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'القاعة / المدرسة')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              await ApiService.addTimetableSlot({
                'day_of_week': selectedDay,
                'start_time': startCtrl.text,
                'end_time': endCtrl.text,
                'grade_id': 8,
                'subject_id': 1,
                'section': sectionCtrl.text,
                'classroom': roomCtrl.text,
                'reminder_minutes': 15,
              });
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              _loadAllData();
            },
            child: const Text('حفظ الحصة والتنبيه'),
          ),
        ],
      ),
    );
  }

  void _showUpdateProgressDialog() {
    final topicCtrl = TextEditingController();
    final pageCtrl = TextEditingController();
    final sectionCtrl = TextEditingController(text: 'شعبة أ');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('أين توقفت مع الشعبة؟'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: sectionCtrl, decoration: const InputDecoration(labelText: 'الشعبة (مثل: أ، ب)')),
            TextField(controller: topicCtrl, decoration: const InputDecoration(labelText: 'آخر عنوان درس شرحته')),
            TextField(controller: pageCtrl, decoration: const InputDecoration(labelText: 'رقم الصفحة')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (topicCtrl.text.isNotEmpty) {
                await ApiService.updateProgress(8, sectionCtrl.text, topicCtrl.text, pageCtrl.text);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                _loadAllData();
              }
            },
            child: const Text('حفظ نقطة التوقف'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog() {
    final noteCtrl = TextEditingController();
    final sectionCtrl = TextEditingController(text: 'شعبة أ');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ملاحظة سريعة للصف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: sectionCtrl, decoration: const InputDecoration(labelText: 'الشعبة')),
            TextField(controller: noteCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'اكتب ملاحظتك للحصة القادمة...')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (noteCtrl.text.isNotEmpty) {
                await ApiService.addNote(8, sectionCtrl.text, noteCtrl.text);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                _loadAllData();
              }
            },
            child: const Text('حفظ الملاحظة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتب وأدوات الأستاذ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month_rounded), text: 'جدول الحصص'),
            Tab(icon: Icon(Icons.bookmark_added_rounded), text: 'أين توقفت؟'),
            Tab(icon: Icon(Icons.sticky_note_2_rounded), text: 'مفكرة الصف'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTimetableTab(colorScheme),
                _buildProgressTab(colorScheme),
                _buildNotesTab(colorScheme),
              ],
            ),
    );
  }

  Widget _buildTimetableTab(ColorScheme colorScheme) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTimetableDialog,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('إضافة حصة'),
      ),
      body: _timetable.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_note_rounded, size: 54, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('لم تضف حصصاً بعد في جدولك الأسبوعي'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _showAddTimetableDialog, child: const Text('إضافة أول حصة')),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _timetable.length,
              itemBuilder: (ctx, i) {
                final item = _timetable[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.school_rounded, color: colorScheme.onPrimaryContainer),
                    ),
                    title: Text('${item['subject_name']} • ${item['grade_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('${item['start_time']} إلى ${item['end_time']} • ${item['section']} • تنبيه قبل ${item['reminder_minutes']} د'),
                    trailing: const Icon(Icons.alarm_on_rounded, color: Colors.teal),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProgressTab(ColorScheme colorScheme) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUpdateProgressDialog,
        icon: const Icon(Icons.edit_location_alt_rounded),
        label: const Text('تحديث التوقف'),
      ),
      body: _progressList.isEmpty
          ? const Center(child: Text('اضغط على الزر بالأسفل لتحديد أين توقفت مع كل شعبة'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _progressList.length,
              itemBuilder: (ctx, i) {
                final item = _progressList[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item['grade_name']} - ${item['section']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const Chip(label: Text('آخر نقطة توقف', style: TextStyle(fontSize: 10))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('الدرس: ${item['last_topic']}', style: const TextStyle(fontSize: 13, color: Colors.teal, fontWeight: FontWeight.bold)),
                        if (item['page_number'] != null) Text('الصفحة: ${item['page_number']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNotesTab(ColorScheme colorScheme) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        icon: const Icon(Icons.note_add_rounded),
        label: const Text('ملاحظة جديدة'),
      ),
      body: _notesList.isEmpty
          ? const Center(child: Text('لا توجد ملاحظات صفية مسجلة حالياً'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notesList.length,
              itemBuilder: (ctx, i) {
                final item = _notesList[i];
                return Card(
                  color: Colors.amber.shade50,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const Icon(Icons.push_pin_rounded, color: Colors.amber),
                    title: Text(item['note_content'], style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    subtitle: Text('${item['grade_name']} • ${item['section']}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ),
                );
              },
            ),
    );
  }
}
