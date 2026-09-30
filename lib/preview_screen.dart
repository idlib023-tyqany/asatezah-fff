import 'package:flutter/material.dart';

import 'main.dart' show RootScreen;
import 'models/file_item.dart';
import 'screens/admin/admin_catalog.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/admin_file_review.dart';
import 'screens/admin/admin_notify.dart';
import 'screens/admin/admin_panel.dart';
import 'screens/admin/admin_reports.dart';
import 'screens/admin/admin_settings.dart';
import 'screens/admin/admin_users.dart';
import 'screens/app_info/app_info_screen.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/file_detail/file_detail_screen.dart';
import 'screens/library/home_screen.dart';
import 'screens/library/offline_files_screen.dart';
import 'screens/library/search_portal.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/support/conversation_screen.dart';
import 'screens/support/inbox_screen.dart';
import 'screens/upload/upload_screen.dart';
import 'widgets/app_logo.dart';

import 'package:asatezah/models/file_stats.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  _PreviewItem? _selected;
  String _searchQuery = '';
  String _selectedGroup = 'الكل';

  static final _sampleFile = FileItem(
    id: -1,
    title: 'ملف تجريبي للمعاينة',
    description: 'بيانات مؤقتة لعرض الواجهة فقط.',
    filename: 'preview_document.pdf',
    mimeType: 'application/pdf',
    fileSize: 2457600,
    category: CategoryInfo(id: -1, name: 'رياضيات'),
    material: CategoryInfo(id: -2, name: 'ملخص'),
    status: 'approved',
    stats: FileStats(
      viewsCount: 120,
      downloadsCount: 35,
      favoritesCount: 12,
      avgRating: 4.5,
      ratingsCount: 18,
    ),
    isFavorite: false,
    createdAt: DateTime(2026, 1, 1),
  );

  late final List<_PreviewItem> _items = [
    _PreviewItem('لوحة الإدارة', 'إدارة', Icons.dashboard_outlined, () => const AdminPanel()),
    _PreviewItem('لوحة التحكم', 'إدارة', Icons.analytics_outlined, () => const AdminDashboard()),
    _PreviewItem('كتالوج الإدارة', 'إدارة', Icons.category_outlined, () => const AdminCatalog()),
    _PreviewItem(
      'مراجعة الملفات',
      'إدارة',
      Icons.fact_check_outlined,
      () => const AdminFileReview(status: 'pending', title: 'الملفات قيد المراجعة'),
    ),
    _PreviewItem('إشعار المستخدمين', 'إدارة', Icons.campaign_outlined, () => const AdminNotify()),
    _PreviewItem('تقارير الإدارة', 'إدارة', Icons.bar_chart_outlined, () => const AdminReports()),
    _PreviewItem('إعدادات الإدارة', 'إدارة', Icons.settings_outlined, () => const AdminSettings()),
    _PreviewItem('المستخدمون', 'إدارة', Icons.people_outline, () => const AdminUsers()),
    _PreviewItem('عن التطبيق', 'التطبيق', Icons.info_outline, () => const AppInfoScreen()),
    _PreviewItem(
      'إكمال الملف الشخصي',
      'المصادقة',
      Icons.person_outline,
      () => const CompleteProfileScreen(),
    ),
    _PreviewItem('تسجيل الدخول', 'المصادقة', Icons.login, () => const LoginScreen()),
    _PreviewItem('إنشاء حساب', 'المصادقة', Icons.person_add_outlined, () => const RegisterScreen()),
    _PreviewItem('المفضلة', 'المكتبة', Icons.favorite_border, () => const FavoritesScreen()),
    _PreviewItem(
      'تفاصيل الملف',
      'الملفات',
      Icons.description_outlined,
      () => FileDetailScreen(file: _sampleFile),
    ),
    _PreviewItem('الرئيسية', 'المكتبة', Icons.home_outlined, () => const HomeScreen()),
    _PreviewItem(
      'الملفات دون اتصال',
      'المكتبة',
      Icons.offline_pin_outlined,
      () => const OfflineFilesScreen(),
    ),
    _PreviewItem('البحث', 'المكتبة', Icons.search, () => const SearchPortalPage()),
    _PreviewItem(
      'الإشعارات',
      'التطبيق',
      Icons.notifications_none,
      () => const NotificationsScreen(),
    ),
    _PreviewItem(
      'المحادثة',
      'الدعم',
      Icons.forum_outlined,
      () => const ConversationScreen(conversationId: -1, subject: 'محادثة تجريبية'),
    ),
    _PreviewItem('صندوق الدعم', 'الدعم', Icons.inbox_outlined, () => const InboxScreen()),
    _PreviewItem('رفع ملف', 'الملفات', Icons.upload_file_outlined, () => const UploadScreen()),
  ];

  List<String> get _groups {
    final groups = _items.map((e) => e.group).toSet().toList();
    return ['الكل', ...groups];
  }

  List<_PreviewItem> get _filteredItems {
    return _items.where((item) {
      final matchesGroup = _selectedGroup == 'الكل' || item.group == _selectedGroup;
      final matchesSearch =
          _searchQuery.isEmpty ||
          item.title.contains(_searchQuery) ||
          item.group.contains(_searchQuery);
      return matchesGroup && matchesSearch;
    }).toList();
  }

  void _openScreen(_PreviewItem item) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => item.builder()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة الواجهات'),
        actions: [
          TextButton.icon(
            onPressed: () =>
                Navigator.of(context)
                    .pushReplacement(MaterialPageRoute(builder: (_) => const RootScreen())),
            icon: const Icon(Icons.play_arrow),
            label: const Text('الوضع الطبيعي'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // رأس الصفحة مع اللوجو والبحث
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  const AppLogo(size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'أساتذة',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // حقل البحث
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'بحث في الواجهات...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            // شريط تصفية المجموعات
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _groups.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  final isSelected = group == _selectedGroup;
                  return ChoiceChip(
                    label: Text(group),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedGroup = group);
                      }
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // شبكة الواجهات
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('لا توجد واجهات تطابق البحث'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        mainAxisExtent: 128,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final selected = item == _selected;

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => _selected = item),
                          onDoubleTap: () {
                            setState(() => _selected = item);
                            _openScreen(item);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: selected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    item.icon,
                                    color: selected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.primary,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.title,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: selected ? theme.colorScheme.onPrimaryContainer : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.group,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // شريط الإجراء السفلي
            if (_selected != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openScreen(_selected!),
                      icon: const Icon(Icons.open_in_new),
                      label: Text('فتح الواجهة: ${_selected!.title}'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewItem {
  const _PreviewItem(this.title, this.group, this.icon, this.builder);
  final String title;
  final String group;
  final IconData icon;
  final Widget Function() builder;
}
