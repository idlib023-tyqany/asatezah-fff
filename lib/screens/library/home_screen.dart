import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/file_item.dart';
import '../../services/auth_service.dart';
import '../../services/library_service.dart';
import '../../widgets/file_card.dart';
import '../admin/admin_panel.dart';
import '../app_info/app_info_screen.dart';
import '../auth/login_screen.dart';
import '../favorites/favorites_screen.dart';
import '../file_detail/file_detail_screen.dart';
import '../notifications/notifications_screen.dart';
import '../support/inbox_screen.dart';
import '../upload/upload_screen.dart';
import 'offline_files_screen.dart';
import 'search_portal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  final List<Widget> _tabs = const [
    _KeepAliveWrapper(child: LibraryTab()),
    _KeepAliveWrapper(child: FavoritesScreen()),
    _KeepAliveWrapper(child: InboxScreen()),
    _KeepAliveWrapper(child: AppInfoScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: 'المكتبة'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), label: 'المفضلة'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), label: 'الدعم'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'حول'),
        ],
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
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

    if (!mounted) return;
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
      Navigator.of(context)
          .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المكتبة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'بوابة البحث',
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const SearchPortalPage())),
          ),
          IconButton(
            icon: const Icon(Icons.offline_pin_outlined),
            tooltip: 'الملفات المتاحة دون اتصال',
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const OfflineFilesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') _logout();
              if (v == 'delete_account') _deleteAccountDialog();
              if (v == 'offline') {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const OfflineFilesScreen()));
              }
              if (v == 'admin') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPanel()));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'offline', child: Text('الملفات دون اتصال')),
              if (user?.isAdmin == true)
                const PopupMenuItem(value: 'admin', child: Text('لوحة الإدارة')),
              const PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
              const PopupMenuItem(value: 'delete_account', child: Text('حذف الحساب')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _sortChip(
                    label: 'الأحدث أولاً',
                    selected: _sort == 'latest',
                    onTap: () => _applyFilters(sort: 'latest'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _sortChip(
                    label: 'الأكثر تحميلاً',
                    selected: _sort == 'most_downloaded',
                    onTap: () => _applyFilters(sort: 'most_downloaded'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: _openFilterSheet,
                  tooltip: 'الفلاتر',
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadMore(reset: true),
              child: _all.isEmpty
                  ? _buildEmpty()
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _all.length + (_loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _all.length) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final file = _all[index];
                        return FileCard(
                          file: file,
                          onTap: () async {
                            await Navigator.of(
                              context,
                            ).push(MaterialPageRoute(builder: (_) => FileDetailScreen(file: file)));
                            if (mounted) _loadMore(reset: true);
                          },
                          onFavorite: () => _toggleFavorite(file),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: (user?.canContribute ?? false)
          ? FloatingActionButton(
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const UploadScreen())),
              child: const Icon(Icons.upload_file),
            )
          : null,
    );
  }

  Widget _sortChip({required String label, required bool selected, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.transparent : AppTheme.borderColor),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(Icons.folder_open, size: 60, color: AppTheme.borderColor),
        SizedBox(height: 16),
        Text(
          'لا توجد ملفات',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SortFilterSheet(
        currentCategory: _categoryId,
        currentMaterial: _materialId,
        currentMinRating: _minRating,
        onApply: (category, material, rating) {
          Navigator.pop(ctx);
          _applyFilters(categoryId: category, materialId: material, minRating: rating);
        },
      ),
    );
  }

  Future<void> _deleteAccountDialog() async {
    final password = await _showPasswordDialog();
    if (password == null || password.isEmpty) return;

    try {
      await _auth.deleteAccount(password);
      if (mounted) {
        Navigator.of(
          context,
        ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
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
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تأكيد حذف الحساب'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'أدخل كلمة المرور للتأكيد'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('حذف'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}

class SortFilterSheet extends StatefulWidget {
  final int? currentCategory;
  final int? currentMaterial;
  final int? currentMinRating;
  final void Function(int?, int?, int?) onApply;

  const SortFilterSheet({
    super.key,
    this.currentCategory,
    this.currentMaterial,
    this.currentMinRating,
    required this.onApply,
  });

  @override
  State<SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends State<SortFilterSheet> {
  int? _category;
  int? _material;
  int? _rating;
  List<dynamic> _categories = [];
  List<dynamic> _materials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _category = widget.currentCategory;
    _material = widget.currentMaterial;
    _rating = widget.currentMinRating;
    _load();
  }

  Future<void> _load() async {
    try {
      final filters = await LibraryService().fetchFilters();
      if (!mounted) return;
      setState(() {
        _categories = filters.categories;
        _materials = filters.materials;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'الفلاتر',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _category = null;
                        _material = null;
                        _rating = null;
                      });
                    },
                    child: const Text('مسح'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('التقييم', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _ratingChip('أي تقييم', null),
                  _ratingChip('4+', 4),
                  _ratingChip('3+', 3),
                  _ratingChip('2+', 2),
                ],
              ),
              const SizedBox(height: 20),
              Text('التخصص / الصف', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (_loading)
                const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())
              else if (_categories.isEmpty)
                const Text('لا توجد تصنيفات')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories
                      .map(
                        (c) => FilterChip(
                          label: Text(c.name),
                          selected: _category == c.id,
                          onSelected: (_) {
                            setState(() => _category = _category == c.id ? null : c.id);
                          },
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 20),
              Text('المادة', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (_loading)
                const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())
              else if (_materials.isEmpty)
                const Text('لا توجد مواد')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _materials
                      .map(
                        (m) => FilterChip(
                          label: Text(m.name),
                          selected: _material == m.id,
                          onSelected: (_) {
                            setState(() => _material = _material == m.id ? null : m.id);
                          },
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => widget.onApply(_category, _material, _rating),
                  child: const Text('تطبيق الفلاتر'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ratingChip(String label, int? value) {
    final selected = _rating == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _rating = value),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
