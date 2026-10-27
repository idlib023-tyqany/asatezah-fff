import 'package:flutter/material.dart';

import 'package:asatezah/features/notifications/notifications/notifications_service.dart';
import 'package:asatezah/features/notifications/notifications/notifications_model.dart';

import './notifications_view.dart';

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
    _load(isInitial: true);
  }

  Future<void> _load({bool isInitial = false}) async {
    if (isInitial) {
      setState(() => _loading = true);
    }

    try {
      final items = await _service.fetchNotifications();
      if (mounted) {
        setState(() => _items = items.notifications);
      }
    } catch (_) {
      if (mounted && isInitial) {
        setState(() => _items = []);
      }
    } finally {
      if (mounted && isInitial) {
        setState(() => _loading = false);
      }
    }
  }

  /// تحديد الكل كمقروء بتحديث فورى (Optimistic Update)
  Future<void> _markAll() async {
    if (_items.isEmpty) return;

    final previousItems = List<AppNotification>.from(_items);

    // تحديث الشاشة فوراً
    setState(() {
      _items = _items.map((n) => n.copyWith(read: true)).toList();
    });

    try {
      await _service.markAllRead();
    } catch (e) {
      // إعادة الحالة السابقة في حال فشل الطلب
      if (mounted) {
        setState(() => _items = previousItems);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل تحديث الإشعارات، يرجى المحاولة لاحقاً'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// تحديد إشعار فردي كمقروء بتحديث فورى
  Future<void> _read(AppNotification n) async {
    if (n.read) return;

    final index = _items.indexWhere((x) => x.id == n.id);
    if (index == -1) return;

    final originalItem = _items[index];

    // تحديث الواجهة مباشرة
    setState(() {
      _items[index] = n.copyWith(read: true);
    });

    try {
      await _service.markRead(n.id);
    } catch (_) {
      // إرجاع الحالة السابقة إذا فشلت العملية
      if (mounted) {
        setState(() {
          _items[index] = originalItem;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationsView(
      notifications: _items,
      isLoading: _loading,
      onRefresh: () => _load(isInitial: false),
      onMarkAllRead: _markAll,
      onRead: _read,
    );
  }
}
