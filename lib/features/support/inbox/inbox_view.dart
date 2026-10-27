import 'package:flutter/material.dart';

import 'package:asatezah/features/support/conversation/conversation_model.dart';

class InboxView extends StatelessWidget {
  const InboxView({
    required this.conversations,
    required this.isLoading,
    required this.onNewConversation,
    required this.onRefresh,
    required this.onOpenConversation,
    super.key,
  });

  final List<Conversation> conversations;
  final bool isLoading;
  final VoidCallback onNewConversation;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Conversation conversation) onOpenConversation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدعم الفني'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onNewConversation,
        icon: const Icon(Icons.add_comment),
        label: const Text('محادثة جديدة'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: onRefresh,
              child: conversations.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: conversations.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        final closed = conversation.status == 'closed';

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
                            conversation.subject,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: closed ? Colors.grey.shade700 : Colors.black87,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
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
                          ),
                          trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                          onTap: () => onOpenConversation(conversation),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(Icons.support_agent, size: 70, color: Colors.grey),
        SizedBox(height: 16),
        Center(
          child: Text(
            'لا توجد محادثات قائمة',
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
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
    );
  }
}
