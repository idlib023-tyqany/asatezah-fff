import 'package:flutter/material.dart';

import 'package:asatezah/features/support/inbox/inbox_widget.dart';

import './admin_panel_view.dart';
import '../admin_catalog/admin_catalog_widget.dart';
import '../file_review/file_review_widget.dart';
import '../admin_notify/admin_notify_widget.dart';
import '../admin_reports/admin_reports_widget.dart';
import '../admin_settings/admin_settings_widget.dart';
import '../admin_users/admin_users_widget.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <AdminPanelItem>[
      AdminPanelItem(
        icon: Icons.pending_actions_rounded,
        label: 'مراجعة الملفات',
        screen: const AdminFileReview(status: 'pending', title: 'قيد المراجعة'),
        color: Colors.amber.shade800,
      ),
      AdminPanelItem(
        icon: Icons.published_with_changes_rounded,
        label: 'الملفات المنشورة',
        screen: const AdminFileReview(status: 'published', title: 'المنشورة'),
        color: Colors.green.shade700,
      ),
      AdminPanelItem(
        icon: Icons.delete_outline_rounded,
        label: 'سلة المهملات',
        screen: const AdminFileReview(status: 'trashed', title: 'سلة المهملات'),
        color: Colors.red.shade700,
      ),
      AdminPanelItem(
        icon: Icons.people_outline_rounded,
        label: 'المستخدمون',
        screen: const AdminUsers(),
        color: Colors.blue.shade700,
      ),
      AdminPanelItem(
        icon: Icons.warning_amber_rounded,
        label: 'البلاغات',
        screen: const AdminReports(),
        color: Colors.orange.shade800,
      ),
      AdminPanelItem(
        icon: Icons.notifications_active_outlined,
        label: 'إرسال إشعار',
        screen: const AdminNotify(),
        color: Colors.purple.shade700,
      ),
      AdminPanelItem(
        icon: Icons.support_agent_rounded,
        label: 'دعم المستخدمين',
        screen: const InboxScreen(),
        color: Colors.teal.shade700,
      ),
      AdminPanelItem(
        icon: Icons.category_outlined,
        label: 'الصفوف والمواد والمجلدات',
        screen: const AdminCatalog(),
        color: Colors.indigo.shade700,
      ),
      AdminPanelItem(
        icon: Icons.settings_outlined,
        label: 'الإعدادات',
        screen: const AdminSettings(),
        color: Colors.blueGrey.shade700,
      ),
    ];

    return AdminPanelView(
      items: items,
      onOpen: (screen) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      },
    );
  }
}
