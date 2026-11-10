import 'package:asatezah/features/teacher_ai/teacher_ai_widget.dart';
import 'package:flutter/material.dart';

import 'package:asatezah/features/admin/admin_panel/admin_panel_widget.dart';
import 'package:asatezah/features/app_info/app_info_widget.dart';
import 'package:asatezah/features/auth/auth_service.dart';
import 'package:asatezah/features/auth/login/login_widget.dart';
import 'package:asatezah/features/auth/profile_settings_widget.dart';
import 'package:asatezah/features/favorites/favorites_widget.dart';
import 'package:asatezah/features/library/home/home_view.dart';
import 'package:asatezah/features/library/folders/folders_widget.dart';
import 'package:asatezah/features/notifications/notifications_widget.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_service.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';
import 'package:asatezah/features/resource_hub/file_detail/file_detail_widget.dart';
import 'package:asatezah/features/resource_hub/upload/upload_widget.dart';
import 'package:asatezah/features/support/inbox/inbox_widget.dart';

import '../offline_files/offline_files_widget.dart';
import '../search_portal/search_portal_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({this.previewMode = false, super.key});

  final bool previewMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.previewMode) {
      return HomeView(
        tabIndex: _tabIndex,
        onTabSelected: (index) => setState(() => _tabIndex = index),
        tabs: [
          const _PreviewLibraryTab(),
          const _PreviewPlaceholderTab(
            icon: Icons.favorite_border,
            label: 'المفضلة التجريبية',
          ),
          const _PreviewPlaceholderTab(
            icon: Icons.support_agent_outlined,
            label: 'الدعم التجريبي',
          ),
          const _PreviewPlaceholderTab(
            icon: Icons.info_outline,
            label: 'عن أساتذة',
          ),
        ],
      );
    }

    return HomeView(
      tabIndex: _tabIndex,
      onTabSelected: (index) => setState(() => _tabIndex = index),
      tabs: const [
        LibraryTab(),
        TeacherAiWidget(),
        FavoritesScreen(),
        InboxScreen(),
        AppInfoScreen(),
      ],
    );
  }
}

class _PreviewLibraryTab extends StatefulWidget {
  const _PreviewLibraryTab();

  @override
  State<_PreviewLibraryTab> createState() => _PreviewLibraryTabState();
}

class _PreviewLibraryTabState extends State<_PreviewLibraryTab> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LibraryTabView(
      files: [
        FileItem(
          id: -1,
          title: 'ملخص الرياضيات للصف التاسع',
          description: 'محتوى تجريبي لمعاينة بطاقة الملف.',
          filename: 'math-summary.pdf',
          mimeType: 'application/pdf',
          fileSize: 2457600,
          category: CategoryInfo(id: -1, name: 'الرياضيات'),
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
        ),
        FileItem(
          id: -2,
          title: 'مراجعة العلوم العامة',
          description: 'ملف تجريبي آخر للعرض داخل المكتبة.',
          filename: 'science-review.pdf',
          mimeType: 'application/pdf',
          fileSize: 1843200,
          category: CategoryInfo(id: -3, name: 'العلوم'),
          material: CategoryInfo(id: -4, name: 'مراجعة'),
          status: 'approved',
          stats: FileStats(
            viewsCount: 86,
            downloadsCount: 21,
            favoritesCount: 8,
            avgRating: 4.2,
            ratingsCount: 11,
          ),
          isFavorite: true,
          createdAt: DateTime(2026, 1, 2),
        ),
      ],
      isLoading: false,
      sort: 'latest',
      isAdmin: false,
      canContribute: false,
      scrollController: _scrollController,
      onRefresh: () async {},
      onSortChanged: (_) {},
      onOpenFilters: () {},
      onOpenFile: (_) async {},
      onFavorite: (_) {},
      onSearch: () {},
      onFolders: () {},
      onOfflineFiles: () {},
      onNotifications: () {},
      onAdmin: () {},
      onLogout: () {},
      onDeleteAccount: () {},
      onUpload: () {},
      onProfile: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ProfileSettingsScreen(previewMode: true),
          ),
        );
      },
    );
  }
}

class _PreviewPlaceholderTab extends StatelessWidget {
  const _PreviewPlaceholderTab({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52),
            const SizedBox(height: 12),
            Text(label),
            const SizedBox(height: 8),
            const Text('هذه مساحة تجريبية للمعاينة فقط.'),
          ],
        ),
      ),
    );
  }
}

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  final _library = LibraryService();
  final _auth = AuthService();
  final _scrollController = ScrollController();

  String _sort = 'latest';
  int? _categoryId;
  int? _materialId;
  int? _minRating;
  int _page = 1;
  List<FileItem> _all = [];
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMore(reset: true);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_loading) return;
    if (!reset && !_hasMore) return;

    setState(() => _loading = true);

    final page = reset ? 1 : _page + 1;
    try {
      final result = await _library.fetchFiles(
        page: page,
        sort: _sort,
        categoryId: _categoryId,
        materialId: _materialId,
        minRating: _minRating,
      );

      if (!mounted) return;

      setState(() {
        if (reset) {
          _all = result.files;
          _page = 1;
        } else {
          _all.addAll(result.files);
          _page = page;
        }
        _hasMore = page < result.lastPage;
      });
    } catch (e) {
      if (mounted && reset) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذّر تحميل الملفات: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyFilters({
    String? sort,
    int? categoryId,
    int? materialId,
    int? minRating,
  }) async {
    _sort = sort ?? _sort;
    _categoryId = categoryId;
    _materialId = materialId;
    _minRating = minRating;

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    setState(() => _all.clear());
    await _loadMore(reset: true);
  }

  void _updateFileInList(FileItem updated) {
    final index = _all.indexWhere((item) => item.id == updated.id);
    if (index != -1) {
      setState(() {
        _all[index] = updated;
      });
    }
  }

  Future<void> _toggleFavorite(FileItem file) async {
    final oldStatus = file.isFavorite;
    final updatedFile = file.copyWith(isFavorite: !oldStatus);

    _updateFileInList(updatedFile);

    try {
      if (oldStatus) {
        await _library.removeFavorite(file.id);
      } else {
        await _library.addFavorite(file.id);
      }
    } catch (_) {
      if (mounted) {
        _updateFileInList(file.copyWith(isFavorite: oldStatus));
      }
    }
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _openFile(FileItem file) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => FileDetailScreen(file: file)));
    if (mounted) _loadMore(reset: true);
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => LibraryFilterSheetView(
        currentCategory: _categoryId,
        currentMaterial: _materialId,
        currentMinRating: _minRating,
        onLoadOptions: _loadFilterOptions,
        onApply: (category, material, rating) {
          Navigator.pop(sheetContext);
          _applyFilters(
            categoryId: category,
            materialId: material,
            minRating: rating,
          );
        },
      ),
    );
  }

  Future<LibraryFilterOptions> _loadFilterOptions() async {
    final filters = await _library.fetchFilters();
    return LibraryFilterOptions(
      categories: filters.categories,
      materials: filters.materials,
    );
  }

  Future<void> _deleteAccountDialog() async {
    final password = await _showPasswordDialog();
    if (password == null || password.isEmpty) return;

    try {
      await _auth.deleteAccount(password);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('كلمة المرور غير صحيحة'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String?> _showPasswordDialog() async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('تأكيد حذف الحساب'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'أدخل كلمة المرور للتأكيد',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return LibraryTabView(
      files: _all,
      isLoading: _loading,
      sort: _sort,
      isAdmin: user?.isAdmin == true,
      canContribute: user?.canContribute ?? false,
      scrollController: _scrollController,
      onRefresh: () => _loadMore(reset: true),
      onSortChanged: (sort) => _applyFilters(sort: sort),
      onOpenFilters: _openFilterSheet,
      onOpenFile: _openFile,
      onFavorite: _toggleFavorite,
      onSearch: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SearchPortalPage()));
      },
      onFolders: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const FoldersScreen()));
      },
      onOfflineFiles: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const OfflineFilesScreen()));
      },
      onNotifications: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      },
      onAdmin: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AdminPanel()));
      },
      onLogout: _logout,
      onDeleteAccount: _deleteAccountDialog,
      onProfile: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
        );
      },
      onUpload: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const UploadScreen()));
      },
    );
  }
}
