import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/support.dart';
import '../../services/support_service.dart';

class ConversationScreen extends StatefulWidget {
  final int conversationId;
  final String subject;
  final bool closed;

  const ConversationScreen({
    super.key,
    required this.conversationId,
    required this.subject,
    this.closed = false,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _service = SupportService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;
  late bool _closed;

  @override
  void initState() {
    super.initState();
    _closed = widget.closed;
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _load() async {
    try {
      final list = await _service.fetchMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = list.items;
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _closed || _sending) return;

    _controller.clear();
    setState(() => _sending = true);

    try {
      final msg = await _service.sendText(widget.conversationId, text);
      if (mounted) {
        setState(() => _messages = [..._messages, msg]);
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر إرسال الرسالة'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage() async {
    if (_closed || _sending) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: false);

    if (result == null || result.files.isEmpty || result.files.first.path == null) {
      return;
    }

    setState(() => _sending = true);

    try {
      final msg = await _service.sendImage(widget.conversationId, result.files.first.path!);
      if (mounted) {
        setState(() => _messages = [..._messages, msg]);
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر إرسال الصورة'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _close() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إغلاق المحادثة'),
        content: const Text('هل أنت تأكد من إغلاق هذه المحادثة؟ لن تتمكن من إرسال رسائل جديدة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.closeConversation(widget.conversationId);
      if (mounted) {
        setState(() => _closed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إغلاق المحادثة بنجاح'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذّر إغلاق المحادثة'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImagePreview(String imagePath) {
    final isNetwork = imagePath.startsWith('http://') || imagePath.startsWith('https://');

    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
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
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject),
        centerTitle: true,
        actions: [
          if (!_closed)
            IconButton(
              onPressed: _close,
              icon: const Icon(Icons.lock_outline),
              tooltip: 'إغلاق المحادثة',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(
                    child: Text('لا توجد رسائل بعد', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _messageBubble(_messages[index]),
                  ),
          ),
          if (_closed)
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
                      onPressed: _sending ? null : _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      color: Theme.of(context).colorScheme.primary,
                      tooltip: 'إرسال صورة',
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_sending,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendText(),
                        decoration: InputDecoration(
                          hintText: 'اكتب رسالتك...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: _sending ? null : _sendText,
                      icon: _sending
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

  Widget _messageBubble(Message m) {
    final mine = m.mine;
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
            if (m.imagePath != null && m.imagePath!.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _showImagePreview(m.imagePath!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageWidget(m.imagePath!),
                ),
              ),
              const SizedBox(height: 6),
            ],
            if (m.body != null && m.body!.isNotEmpty)
              Text(
                m.body!,
                style: TextStyle(color: mine ? Colors.white : Colors.black87, fontSize: 14),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _time(m.createdAt),
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

  Widget _buildImageWidget(String path) {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        path,
        width: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorImageWidget(),
      );
    } else {
      return Image.file(
        File(path),
        width: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorImageWidget(),
      );
    }
  }

  Widget _errorImageWidget() {
    return const Padding(
      padding: EdgeInsets.all(8),
      child: Text('تعذّر تحميل الصورة', style: TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }

  String _time(DateTime d) {
    final now = DateTime.now();
    if (now.difference(d).inDays > 0) {
      return '${d.day}/${d.month}';
    }
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour >= 12 ? 'م' : 'ص';
    return '${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $period';
  }
}
