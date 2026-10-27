import 'package:flutter/material.dart';
import 'package:asatezah/features/admin/admin_catalog/admin_catalog_screen.dart';
import 'package:asatezah/features/admin/admin_dashboard/admin_dashboard_screen.dart';
import 'package:asatezah/features/admin/admin_notify/admin_notify_screen.dart';
import 'package:asatezah/features/admin/admin_panel/admin_panel_screen.dart';
import 'package:asatezah/features/admin/admin_reports/admin_reports_screen.dart';
import 'package:asatezah/features/admin/admin_settings/admin_settings_screen.dart';
import 'package:asatezah/features/admin/admin_users/admin_users_screen.dart';
import 'package:asatezah/features/admin/file_review/file_review_screen.dart';
import 'package:asatezah/features/app_info/app_info_screen.dart';
import 'package:asatezah/features/auth/complete_profile/complete_profile_screen.dart';
import 'package:asatezah/features/auth/login/login_screen.dart';
import 'package:asatezah/features/auth/register/register_screen.dart';
import 'package:asatezah/features/favorites/favorites_screen.dart';
import 'package:asatezah/features/library/home/home_screen.dart';
import 'package:asatezah/features/library/offline_files/offline_files_screen.dart';
import 'package:asatezah/features/library/search_portal/search_portal_screen.dart';
import 'package:asatezah/features/notifications/notifications_screen.dart';
import 'package:asatezah/features/resource_hub/file_detail/file_detail_screen.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';
import 'package:asatezah/features/resource_hub/upload/upload_screen.dart';
import 'package:asatezah/features/support/conversation/conversation_screen.dart';
import 'package:asatezah/features/support/inbox/inbox_screen.dart';
import 'preview_model.dart';

class DevToolsService {
  static final _sampleFile = FileItem(
    id: -1,
    title: 'ملف تجريبي للمعاينة',
    description: 'بيانات مؤقتة لعرض الواجهة واختبار تصميم البطاقات والتفاصيل.',
    filename: 'preview_document.pdf',
    mimeType: 'application/pdf',
    fileSize: 2457600,
    category: const CategoryInfo(id: -1, name: 'رياضيات'),
    material: const CategoryInfo(id: -2, name: 'ملخص'),
    status: 'approved',
    stats: const FileStats(
      viewsCount: 120,
      downloadsCount: 35,
      favoritesCount: 12,
      avgRating: 4.5,
      ratingsCount: 18,
    ),
    isFavorite: false,
    createdAt: DateTime(2026, 1, 1),
  );

  List<PreviewEntry> get entries => [
    PreviewEntry('لوحة الإدارة', 'إدارة', Icons.dashboard_outlined, () => const AdminPanel()),
    PreviewEntry('لوحة التحكم', 'إدارة', Icons.analytics_outlined, () => const AdminDashboard()),
    PreviewEntry('كتالوج الإدارة', 'إدارة', Icons.category_outlined, () => const AdminCatalog()),
    PreviewEntry(
      'مراجعة الملفات',
      'إدارة',
      Icons.fact_check_outlined,
      () => const AdminFileReview(status: 'pending', title: 'الملفات قيد المراجعة'),
    ),
    PreviewEntry('إشعار المستخدمين', 'إدارة', Icons.campaign_outlined, () => const AdminNotify()),
    PreviewEntry('تقارير الإدارة', 'إدارة', Icons.bar_chart_outlined, () => const AdminReports()),
    PreviewEntry('إعدادات الإدارة', 'إدارة', Icons.settings_outlined, () => const AdminSettings()),
    PreviewEntry('المستخدمون', 'إدارة', Icons.people_outline, () => const AdminUsers()),
    PreviewEntry('عن التطبيق', 'التطبيق', Icons.info_outline, () => const AppInfoScreen()),
    PreviewEntry(
      'إكمال الملف الشخصي',
      'المصادقة',
      Icons.person_outline,
      () => const CompleteProfileScreen(),
    ),
    PreviewEntry('تسجيل الدخول', 'المصادقة', Icons.login, () => const LoginScreen()),
    PreviewEntry('إنشاء حساب', 'المصادقة', Icons.person_add_outlined, () => const RegisterScreen()),
    PreviewEntry('المفضلة', 'المكتبة', Icons.favorite_border, () => const FavoritesScreen()),
    PreviewEntry(
      'تفاصيل الملف',
      'الملفات',
      Icons.description_outlined,
      () => FileDetailScreen(file: _sampleFile),
    ),
    PreviewEntry('الرئيسية', 'المكتبة', Icons.home_outlined, () => const HomeScreen()),
    PreviewEntry(
      'الملفات دون اتصال',
      'المكتبة',
      Icons.offline_pin_outlined,
      () => const OfflineFilesScreen(),
    ),
    PreviewEntry('البحث', 'المكتبة', Icons.search, () => const SearchPortalPage()),
    PreviewEntry(
      'الإشعارات',
      'التطبيق',
      Icons.notifications_none,
      () => const NotificationsScreen(),
    ),
    PreviewEntry(
      'المحادثة',
      'الدعم',
      Icons.forum_outlined,
      () => const ConversationScreen(conversationId: -1, subject: 'محادثة تجريبية'),
    ),
    PreviewEntry('صندوق الدعم', 'الدعم', Icons.inbox_outlined, () => const InboxScreen()),
    PreviewEntry('رفع ملف', 'الملفات', Icons.upload_file_outlined, () => const UploadScreen()),
  ];
}
