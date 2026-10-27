import 'package:flutter/material.dart';

import 'package:asatezah/features/notifications/notifications/notifications_model.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({
    required this.notifications,
    required this.isLoading,
    required this.onRefresh,
    required this.onMarkAllRead,
    required this.onRead,
    super.key,
  });

  final List<AppNotification> notifications;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onMarkAllRead;
  final Future<void> Function(AppNotification notification) onRead;

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((notification) => !notification.read).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(unreadCount > 0 ? 'الإشعارات ($unreadCount)' : 'الإشعارات'),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            IconButton(
              onPressed: onMarkAllRead,
              icon: const Icon(Icons.done_all),
              tooltip: 'تحديد الكل كمقروء',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: onRefresh,
              child: notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final primaryColor = Theme.of(context).colorScheme.primary;

                        return Container(
                          color: notification.read
                              ? Colors.transparent
                              : primaryColor.withValues(alpha: 0.05),
                          child: ListTile(
                            onTap: () => onRead(notification),
                            leading: Icon(
                              notification.read
                                  ? Icons.notifications_none_outlined
                                  : Icons.notifications_active,
                              color: notification.read ? Colors.grey : primaryColor,
                            ),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight:
                                    notification.read ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(notification.body),
                            ),
                            trailing: Text(
                              _formatDate(notification.createdAt),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'لا توجد إشعارات حالياً',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inDays > 0) return 'منذ ${difference.inDays} يوم';
    if (difference.inHours > 0) return 'منذ ${difference.inHours} ساعة';
    if (difference.inMinutes > 0) return 'منذ ${difference.inMinutes} دقيقة';
    return 'الآن';
  }
}
