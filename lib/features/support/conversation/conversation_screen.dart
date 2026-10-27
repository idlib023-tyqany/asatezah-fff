import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:asatezah/features/support/support_service.dart';
import 'package:asatezah/features/support/conversation/conversation_model.dart';

import './conversation_view.dart';

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

    setState(() => _sending = true);

    try {
      final msg = await _service.sendText(widget.conversationId, text);
      if (mounted) {
        _controller.clear(); // تفريغ النص فقط بعد نجاح عملية الإرسال
        setState(() => _messages = [..._messages, msg]);
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذّر إرسال الرسالة، يرجى المحاولة لاحقاً'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage() async {
    if (_closed || _sending) return;

    FocusScope.of(context).unfocus();

    final files = await FilePicker.pickFiles(type: FileType.image);

    if (files.isEmpty || files.first.path == null) {
      return;
    }

    setState(() => _sending = true);

    try {
      final msg = await _service.sendImage(widget.conversationId, files.first.path!);
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

  @override
  Widget build(BuildContext context) {
    return ConversationView(
      subject: widget.subject,
      messages: _messages,
      isLoading: _loading,
      isSending: _sending,
      isClosed: _closed,
      textController: _controller,
      scrollController: _scrollController,
      onClose: _close,
      onPickImage: _pickImage,
      onSendText: _sendText,
    );
  }
}
