import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';

class TeacherAiScreen extends StatefulWidget {
  const TeacherAiScreen({super.key});

  @override
  State<TeacherAiScreen> createState() => _TeacherAiScreenState();
}

class _TeacherAiScreenState extends State<TeacherAiScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _selectedMode = 'lesson_plan';
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text': 'مرحباً بك يا أستاذ! أنا مساعدك الذكي المربوط بـ Google Gemini 3.8 Flash.\nيمكنني مساعدتك في صياغة خطط الدروس، بنك أسئلة الامتحانات، حساب سلالم وتوزيع الدرجات بدقة، اقتراح الواجبات المنزلية، وتبسيط المفاهيم بتجارب بديلة. بمَ نبدأ؟'
    }
  ];

  void _sendMessage([String? quick]) async {
    final text = quick ?? _promptController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });

    _promptController.clear();

    try {
      final reply = await ApiService.askGemini(text, _selectedMode);
      setState(() {
        _messages.add({'role': 'assistant', 'text': reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'عذراً، حدث خطأ في الاتصال بسيرفر الذكاء الاصطناعي: $e'});
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مساعد المعلم الذكي (Gemini)'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _modeChip('خطة درس', 'lesson_plan', Icons.edit_note),
                  const SizedBox(width: 6),
                  _modeChip('بنك أسئلة وامتحان', 'exam', Icons.quiz_outlined),
                  const SizedBox(width: 6),
                  _modeChip('حاسبة سلم الدرجات', 'grading_scale', Icons.calculate_outlined),
                  const SizedBox(width: 6),
                  _modeChip('واجب منزلي متوازن', 'homework', Icons.assignment_outlined),
                  const SizedBox(width: 6),
                  _modeChip('حل مسائل وتمارين', 'solve', Icons.functions_rounded),
                  const SizedBox(width: 6),
                  _modeChip('تبسيط وتجارب بديلة', 'simplify', Icons.lightbulb_outline),
                  const SizedBox(width: 6),
                  _modeChip('بطاقة قوانين سريعة', 'formula_sheet', Icons.view_headline_rounded),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final isUser = _messages[i]['role'] == 'user';
                final txt = _messages[i]['text'] ?? '';
                return Align(
                  alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                    decoration: BoxDecoration(
                      color: isUser ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(isUser ? 'الأستاذ' : 'Gemini AI', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            const Spacer(),
                            if (!isUser)
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: txt));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الإجابة')));
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(txt, style: const TextStyle(fontSize: 13, height: 1.4)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('جاري الصياغة التربوية وحساب الدرجات عبر Gemini 3.8 Flash...'),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      decoration: InputDecoration(
                        hintText: 'اكتب موضوع الدرس، أو طلب سلم الدرجات، أو الواجب...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: _isLoading ? null : () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String title, String key, IconData icon) {
    final isSelected = _selectedMode == key;
    return ChoiceChip(
      avatar: Icon(icon, size: 14),
      label: Text(title, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedMode = key);
      },
    );
  }
}
