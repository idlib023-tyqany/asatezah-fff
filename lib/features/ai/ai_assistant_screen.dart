import 'package:flutter/material.dart';

import 'gemini_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key}); // تم التحديث لاستخدام super.key

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _controller = TextEditingController();

  String _response = 'أهلاً بك! أنا مساعدك الذكي من أساتذة. كيف يمكنني مساعدتك في دراستك اليوم؟';
  bool _isLoading = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = 'جاري التفكير وتحليل السؤال...';
    });

    final result = await _geminiService.generateText(text);

    setState(() {
      _isLoading = false;
      _response = result ?? 'عذراً، لم أستطع توليد إجابة.';
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المساعد الذكي (Gemini AI)'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // استخدام الطريقة الحديثة بدلاً من withOpacity
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: SingleChildScrollView(
                  child: Text(_response, style: const TextStyle(fontSize: 16, height: 1.5)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'اكتب سؤالك الدراسي هنا (مثلاً: اشرح لي قانون...)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
