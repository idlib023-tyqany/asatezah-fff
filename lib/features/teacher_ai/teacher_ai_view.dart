import 'package:flutter/material.dart';

import 'teacher_ai_model.dart';

class TeacherAiView extends StatelessWidget {
  const TeacherAiView({
    required this.promptController,
    required this.scrollController,
    required this.messages,
    required this.mode,
    required this.isLoading,
    required this.onModeChanged,
    required this.onSend,
    required this.onCopy,
    super.key,
  });

  final TextEditingController promptController;
  final ScrollController scrollController;
  final List<TeacherAiMessage> messages;
  final TeacherAiMode mode;
  final bool isLoading;
  final ValueChanged<TeacherAiMode> onModeChanged;
  final VoidCallback onSend;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('مساعد المعلم الذكي (Gemini)')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in TeacherAiMode.values) ...[
                    ChoiceChip(
                      avatar: Icon(option.icon, size: 14),
                      label: Text(
                        option.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: mode == option,
                      onSelected: (selected) {
                        if (selected) onModeChanged(option);
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message.isUser ? 'الأستاذ' : 'Gemini AI',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            if (!message.isUser)
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () => onCopy(message.text),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          message.text,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('جاري إعداد الإجابة التربوية...'),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: promptController,
                      decoration: InputDecoration(
                        hintText: 'اكتب موضوع الدرس أو طلبك...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: isLoading ? null : onSend,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
