import 'package:flutter/material.dart';

import 'package:asatezah/features/admin/admin_panel/admin_panel_screen.dart';
import 'package:asatezah/features/app_info/app_info_screen.dart';
import 'package:asatezah/features/auth/auth_service.dart';
import 'package:asatezah/features/auth/login/login_screen.dart';
import 'package:asatezah/features/favorites/favorites_screen.dart';
import 'package:asatezah/features/library/home/home_view.dart';
import 'package:asatezah/features/notifications/notifications_screen.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_service.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';
import 'package:asatezah/features/resource_hub/file_detail/file_detail_screen.dart';
import 'package:asatezah/features/resource_hub/upload/upload_screen.dart';
import 'package:asatezah/features/support/inbox/inbox_screen.dart';

import '../offline_files/offline_files_screen.dart';
import '../search_portal/search_portal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return HomeView(
      tabIndex: _tabIndex,
      onTabSelected: (index) => setState(() => _tabIndex = index),
      tabs: const [
        LibraryTab(),
        FavoritesScreen(),
        InboxScreen(),
        AppInfoScreen(),
      ],
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
          SnackBar(content: Text('تعذّر تحميل الملفات: $e'), behavior: SnackBarBehavior.floating),
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
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => FileDetailScreen(file: file)));
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
          _applyFilters(categoryId: category, materialId: material, minRating: rating);
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
            decoration: const InputDecoration(labelText: 'أدخل كلمة المرور للتأكيد'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
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
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SearchPortalPage()));
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
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPanel()));
      },
      onLogout: _logout,
      onDeleteAccount: _deleteAccountDialog,
      onUpload: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UploadScreen()));
      },
    );
  }
}
