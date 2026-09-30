import 'package:flutter/material.dart';

import 'admin_catalog.dart';
import 'admin_file_review.dart';
import 'admin_notify.dart';
import 'admin_reports.dart';
import 'admin_settings.dart';
import 'admin_users.dart';
import '../support/inbox_screen.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final items = <(IconData, String, Widget, Color?)>[
      (
        Icons.pending_actions,
        'مراجعة الملفات',
        const AdminFileReview(status: 'pending', title: 'قيد المراجعة'),
        Colors.amber[800],
      ),
      (
        Icons.published_with_changes,
        'الملفات المنشورة',
        const AdminFileReview(status: 'published', title: 'المنشورة'),
        Colors.green[700],
      ),
      (
        Icons.delete_outline,
        'سلة المهملات',
        const AdminFileReview(status: 'trashed', title: 'سلة المهملات'),
        Colors.red[700],
      ),
      (Icons.people_outline, 'المستخدمون', const AdminUsers(), Colors.blue[700]),
      (Icons.warning_amber_outlined, 'البلاغات', const AdminReports(), Colors.orange[800]),
      (Icons.notifications_outlined, 'إرسال إشعار', const AdminNotify(), Colors.purple[700]),
      (Icons.support_agent_outlined, 'دعم المستخدمين', const InboxScreen(), Colors.teal[700]),
      (
        Icons.category_outlined,
        'الصفوف والمواد والمجلدات',
        const AdminCatalog(),
        Colors.indigo[700],
      ),
      (Icons.settings_outlined, 'الإعدادات', const AdminSettings(), Colors.blueGrey[700]),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم والإدارة'), centerTitle: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // جعل عدد الأعمدة متجاوباً حسب عرض الشاشة
          final crossAxisCount = constraints.maxWidth > 900
              ? 4
              : constraints.maxWidth > 600
              ? 3
              : 2;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.15,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              final (icon, label, screen, iconColor) = items[index];
              final color = iconColor ?? primary;

              return Card(
                elevation: 2,
                clipBehavior: Clip.antiAlias, // لضمان قص تأثير InkWell على الحواف
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 28, color: color),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
