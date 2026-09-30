import 'package:flutter/material.dart';

import '../../models/support.dart';
import '../../services/support_service.dart';
import 'conversation_screen.dart';

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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذّر تحميل المحادثات')));
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

    if (subject == null || subject.isEmpty) return;

    // إظهار مؤشر تحميل أثناء البدء
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final conversation = await _service.startConversation(subject);
      if (mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل
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
        Navigator.pop(context); // إغلاق مؤشر التحميل
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذّر فتح المحادثة، يرجى المحاولة لاحقاً')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدعم الفني'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newConversation,
        icon: const Icon(Icons.add_comment),
        label: const Text('محادثة جديدة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(showLoading: false),
              child: _conversations.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.support_agent, size: 70, color: Colors.grey),
                        SizedBox(height: 16),
                        Center(
                          child: Text(
                            'لا توجد محادثات قائمة',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 6),
                        Center(
                          child: Text(
                            'اضغط على زر "محادثة جديدة" للبدء',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _conversations.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final c = _conversations[index];
                        final closed = c.status == 'closed';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: closed
                                ? Colors.grey.shade300
                                : Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              closed ? Icons.lock_outline : Icons.support_agent,
                              color: closed
                                  ? Colors.grey.shade700
                                  : Theme.of(context).colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            c.subject,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: closed ? Colors.grey.shade700 : Colors.black87,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: closed ? Colors.grey.shade200 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: closed ? Colors.grey.shade400 : Colors.green.shade300,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    closed ? 'مغلقة' : 'مفتوحة',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: closed ? Colors.grey.shade700 : Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ConversationScreen(
                                  conversationId: c.id,
                                  subject: c.subject,
                                  closed: closed,
                                ),
                              ),
                            );
                            _load(showLoading: false);
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
