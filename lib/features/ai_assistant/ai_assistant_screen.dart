import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asatezah/core/theme/app_theme.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    '📝 لخص لي ملخص الرياضيات',
    '❓ أنشئ لي 5 أسئلة اختيار من متعدد في مادة العلوم',
    '💡 اشرح لي قانون الجاذبية بأسلوب مبسط',
    '📅 خطة لتنظيم المذاكرة لامتحانات الأسبوع القادم',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text: 'مرحباً بك في مساعد "أساتذة" الذكي! 🎓✨\nأنا هنا لمساعدتك في شرح الدروس، تلخيص الملازم، والإجابة عن أي استفسار دراسي. كيف يمكنني مساعدتك اليوم؟',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? textToSend]) {
    final query = (textToSend ?? _controller.text).trim();
    if (query.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: query, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
      _controller.clear();
    });

    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            text: _generateEducationalResponse(query),
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    });
  }

  String _generateEducationalResponse(String query) {
    if (query.contains('رياضيات') || query.contains('لخص')) {
      return '📌 **ملخص المفاهيم الأساسية:**\n1. ركز دائماً على القوانين والمبرهنات الأساسية.\n2. ابدأ بحل الأمثلة المحلولة في الملزمة أولاً.\n3. تحقق من الوحدات والرموز الرياضية في كل خطوة.\n\nهل تود مني توليد مسائل تدريبية مع الحل؟';
    } else if (query.contains('سؤال') || query.contains('أسئلة') || query.contains('علوم')) {
      return '🎯 **نموذج اختبار تجريبي سريع:**\n\n**السؤال 1:** ما هي وحدة قياس القوة في النظام الدولي؟\nأ) الجول  ب) النيوتن  ج) الواط\n*(الإجابة الصحيحة: ب - النيوتن)*\n\n**السؤال 2:** ما هو العضو المسؤول عن تنقية الدم في جسم الإنسان؟\nأ) الكبد  ب) الرئتان  ج) الكليتان\n*(الإجابة الصحيحة: ج - الكليتان)*\n\nتستطيع متابعة المزيد من الأسئلة في أي وقت!';
    } else if (query.contains('خطة') || query.contains('تنظيم')) {
      return '📅 **جدول مقترح لإدارة وقت المذاكرة (تقنية بومودورو):**\n- 40 دقيقة مذاكرة مركزة بدون هواتف.\n- 10 دقائق استراحة وتنشيط ذهني.\n- تكرار الدورة 3 مرات مع مراجعة سريعة لأهم النقاط في آخر 15 دقيقة.';
    }
    return 'شكراً لسؤالك! بخصوص "$query":\nلتحقيق أفضل استيعاب دراسي، أنصحك بقراءة الملاحظات الموجودة في ملزمة المادة داخل قسم "المكتبة"، وحل الأسئلة الملحقة بنهاية كل فصل. إذا كنت تحتاج شرحاً إضافياً لنقطة معينة، اكتبها لي وسأشرحها لك خطوة بخطوة!';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text('مساعد أساتذة الذكي'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'بدء محادثة جديدة',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  _ChatMessage(
                    text: 'تم بدء محادثة جديدة! كيف يمكنني مساعدتك الآن؟ ✨',
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _quickPrompts[index];
                  return ActionChip(
                    label: Text(
                      prompt,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : AppTheme.primaryDark,
                      ),
                    ),
                    backgroundColor: isDark
                        ? AppTheme.primaryDark.withValues(alpha: 0.5)
                        : AppTheme.primarySoft.withValues(alpha: 0.15),
                    side: BorderSide(
                      color: isDark ? Colors.transparent : AppTheme.primarySoft.withValues(alpha: 0.3),
                    ),
                    onPressed: () => _sendMessage(prompt),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, isDark);
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'المساعد يكتب الإجابة التعليمية...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'اكتب سؤالك أو موضوع الدرس هنا...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: AppTheme.primaryColor,
                    onPressed: () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, bool isDark) {
    final bg = message.isUser
        ? AppTheme.primaryColor
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final textColor = message.isUser
        ? Colors.white
        : (isDark ? Colors.grey[200] : Colors.grey[900]);

    return Align(
      alignment: message.isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 4 : 16),
            bottomRight: Radius.circular(message.isUser ? 16 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  message.isUser ? Icons.person_outline : Icons.auto_awesome,
                  size: 14,
                  color: message.isUser ? Colors.white70 : Colors.amber,
                ),
                const SizedBox(width: 6),
                Text(
                  message.isUser ? 'أنت' : 'مساعد أساتذة',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: message.isUser ? Colors.white70 : Colors.amber[700],
                  ),
                ),
                const Spacer(),
                if (!message.isUser)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 14),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    tooltip: 'نسخ الإجابة',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ الإجابة بنجاح!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              message.text,
              style: TextStyle(
                fontSize: 13.5,
                color: textColor,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

