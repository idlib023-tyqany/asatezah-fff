import 'package:flutter/material.dart';

import 'package:asatezah/features/support/support_service.dart';
import 'package:asatezah/features/support/conversation/conversation_model.dart';

import '../conversation/conversation_screen.dart';

import './inbox_view.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _service = SupportService();
  List<Conversation> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    try {
      final list = await _service.fetchInbox();
      if (mounted) {
        setState(() {
          _conversations = list;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _conversations = []);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذّر تحميل المحادثات'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted && showLoading) setState(() => _loading = false);
    }
  }

  Future<void> _newConversation() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final subject = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('محادثة جديدة'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'موضوع المحادثة أو المشكلة',
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'يرجى كتابة الموضوع';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('بدء'),
          ),
        ],
      ),
    );

    // التخلص من المتحكم تحاشياً لتسريب الذاكرة
    controller.dispose();

    if (subject == null || subject.isEmpty) return;

    if (!mounted) return;

    // إظهار مؤشر تحميل أثناء البدء
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final conversation = await _service.startConversation(subject);
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // إغلاق مؤشر التحميل بأمان
        _load(showLoading: false);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ConversationScreen(conversationId: conversation.id, subject: conversation.subject),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // إغلاق مؤشر التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذّر فتح المحادثة، يرجى المحاولة لاحقاً'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openConversation(Conversation conversation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversationScreen(
          conversationId: conversation.id,
          subject: conversation.subject,
          closed: conversation.status == 'closed',
        ),
      ),
    );
    _load(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    return InboxView(
      conversations: _conversations,
      isLoading: _loading,
      onNewConversation: _newConversation,
      onRefresh: () => _load(showLoading: false),
      onOpenConversation: _openConversation,
    );
  }
}
