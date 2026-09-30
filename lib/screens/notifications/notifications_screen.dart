import 'package:flutter/material.dart';

import '../../models/notification.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final items = await _service.fetchNotifications();
      if (mounted) {
        setState(() => _items = items.notifications);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _items = []);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _markAll() async {
    if (_items.isEmpty) return;

    try {
      await _service.markAllRead();
      if (mounted) {
        setState(() {
          _items = _items.map((n) => n.copyWith(read: true)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('فشل تحديث الإشعارات')));
      }
    }
  }

  Future<void> _read(AppNotification n) async {
    if (n.read) return; // تجنب إعادة الطلب إذا كان الإشعار مقروءاً بالفعل

    try {
      await _service.markRead(n.id);
      if (mounted) {
        setState(() {
          _items = _items.map((x) => x.id == n.id ? x.copyWith(read: true) : x).toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
        actions: [
          if (_items.any((n) => !n.read))
            IconButton(
              onPressed: _markAll,
              icon: const Icon(Icons.done_all),
              tooltip: 'تحديد الكل كمقروء',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 150),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('لا توجد إشعارات حالياً', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final n = _items[index];
                        final primaryColor = Theme.of(context).colorScheme.primary;

                        return Container(
                          color: n.read ? Colors.transparent : primaryColor.withValues(alpha: 0.05),
                          child: ListTile(
                            onTap: () => _read(n),
                            leading: Icon(
                              n.read
                                  ? Icons.notifications_none_outlined
                                  : Icons.notifications_active,
                              color: n.read ? Colors.grey : primaryColor,
                            ),
                            title: Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(n.body),
                            ),
                            trailing: Text(
                              _formatDate(n.createdAt),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);

    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }
}
