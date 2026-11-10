import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'teacher_ai_model.dart';
import 'teacher_ai_service.dart';
import 'teacher_ai_view.dart';

class TeacherAiWidget extends StatefulWidget {
  const TeacherAiWidget({super.key});

  @override
  State<TeacherAiWidget> createState() => _TeacherAiWidgetState();
}

class _TeacherAiWidgetState extends State<TeacherAiWidget> {
  final TeacherAiService _service = TeacherAiService();
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<TeacherAiMessage> _messages = [
    const TeacherAiMessage(
      isUser: false,
      text: 'مرحباً بك يا أستاذ! أستطيع مساعدتك في صياغة خطط الدروس والأسئلة وتوزيع الدرجات والواجبات وتبسيط المفاهيم. بمَ نبدأ؟',
    ),
  ];
  TeacherAiMode _mode = TeacherAiMode.lessonPlan;
  bool _isLoading = false;

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(TeacherAiMessage(text: prompt, isUser: true));
      _isLoading = true;
    });
    _promptController.clear();

    try {
      final response = await _service.ask(prompt, _mode.key);
      if (!mounted) return;
      setState(
        () => _messages.add(TeacherAiMessage(text: response, isUser: false)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          TeacherAiMessage(
            text: 'تعذّر الاتصال بالمساعد الذكي: $error',
            isUser: false,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم نسخ الإجابة')));
  }

  @override
  Widget build(BuildContext context) {
    return TeacherAiView(
      promptController: _promptController,
      scrollController: _scrollController,
      messages: _messages,
      mode: _mode,
      isLoading: _isLoading,
      onModeChanged: (mode) => setState(() => _mode = mode),
      onSend: _send,
      onCopy: _copy,
    );
  }
}
