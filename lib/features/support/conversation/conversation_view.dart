import 'dart:io';

import 'package:flutter/material.dart';

import 'package:asatezah/features/support/conversation/conversation_model.dart';

class ConversationView extends StatelessWidget {
  const ConversationView({
    required this.subject,
    required this.messages,
    required this.isLoading,
    required this.isSending,
    required this.isClosed,
    required this.textController,
    required this.scrollController,
    required this.onClose,
    required this.onPickImage,
    required this.onSendText,
    super.key,
  });

  final String subject;
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final bool isClosed;
  final TextEditingController textController;
  final ScrollController scrollController;
  final VoidCallback onClose;
  final VoidCallback onPickImage;
  final VoidCallback onSendText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(subject),
        centerTitle: true,
        actions: [
          if (!isClosed)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.lock_outline),
              tooltip: 'إغلاق المحادثة',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const Center(
                    child: Text('لا توجد رسائل بعد', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) => _messageBubble(context, messages[index]),
                  ),
          ),
          if (isClosed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade200,
              child: const Text(
                'هذه المحادثة مغلقة ولا يمكن إضافة ردود جديدة',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: isSending ? null : onPickImage,
                      icon: const Icon(Icons.image_outlined),
                      color: Theme.of(context).colorScheme.primary,
                      tooltip: 'إرسال صورة',
                    ),
                    Expanded(
                      child: TextField(
                        controller: textController,
                        enabled: !isSending,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSendText(),
                        decoration: InputDecoration(
                          hintText: 'اكتب رسالتك...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: isSending ? null : onSendText,
                      icon: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _messageBubble(BuildContext context, Message message) {
    final mine = message.mine;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(14),
            topLeft: const Radius.circular(14),
            bottomRight: Radius.circular(mine ? 0 : 14),
            bottomLeft: Radius.circular(mine ? 14 : 0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.imagePath != null && message.imagePath!.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _showImagePreview(context, message.imagePath!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageWidget(message.imagePath!),
                ),
              ),
              const SizedBox(height: 6),
            ],
            if (message.body != null && message.body!.isNotEmpty)
              Text(
                message.body!,
                style: TextStyle(color: mine ? Colors.white : Colors.black87, fontSize: 14),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _time(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: mine ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imagePath) {
    final isNetwork = imagePath.startsWith('http://') || imagePath.startsWith('https://');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: isNetwork ? Image.network(imagePath) : Image.file(File(imagePath)),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String path) {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');

    if (isNetwork) {
      return Image.network(path, width: 200, fit: BoxFit.cover, errorBuilder: _imageErrorBuilder);
    }

    return Image.file(File(path), width: 200, fit: BoxFit.cover, errorBuilder: _imageErrorBuilder);
  }

  Widget _imageErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace) =>
      _errorImageWidget();

  Widget _errorImageWidget() {
    return const Padding(
      padding: EdgeInsets.all(8),
      child: Text('تعذّر تحميل الصورة', style: TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }

  String _time(DateTime dateTime) {
    final now = DateTime.now();
    if (now.difference(dateTime).inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    }
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour >= 12 ? 'م' : 'ص';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
}
