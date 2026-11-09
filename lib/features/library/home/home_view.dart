import 'package:asatezah/features/ai/ai_assistant_screen.dart';
import 'package:flutter/material.dart';

import 'package:asatezah/core/theme/app_theme.dart';
import 'package:asatezah/core/widgets/file_card.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';

class HomeView extends StatelessWidget {
  final int tabIndex;
  final List<Widget> tabs;
  final ValueChanged<int> onTabSelected;

  const HomeView({
    super.key,
    required this.tabIndex,
    required this.tabs,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: tabIndex,
        children: tabs.map((tab) => _KeepAliveWrapper(child: tab)).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: tabIndex,
        onTap: onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'لوحة الأستاذ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome, color: Colors.amber),
            label: 'المساعد الذكي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            label: 'المفضلة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent_outlined),
            label: 'الدعم',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'حول'),
        ],
      ),
    );
  }
}

class LibraryTabView extends StatelessWidget {
  final List<FileItem> files;
  final bool isLoading;
  final String sort;
  final bool isAdmin;
  final bool canContribute;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onOpenFilters;
  final Future<void> Function(FileItem file) onOpenFile;
  final ValueChanged<FileItem> onFavorite;
  final VoidCallback onSearch;
  final VoidCallback onFolders;
  final VoidCallback onOfflineFiles;
  final VoidCallback onNotifications;
  final VoidCallback onAdmin;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final VoidCallback onUpload;
  final VoidCallback onProfile;

  const LibraryTabView({
    super.key,
    required this.files,
    required this.isLoading,
    required this.sort,
    required this.isAdmin,
    required this.canContribute,
    required this.scrollController,
    required this.onRefresh,
    required this.onSortChanged,
    required this.onOpenFilters,
    required this.onOpenFile,
    required this.onFavorite,
    required this.onSearch,
    required this.onFolders,
    required this.onOfflineFiles,
    required this.onNotifications,
    required this.onAdmin,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onUpload,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الأستاذ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amber),
            tooltip: 'مساعد أساتذة الذكي',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'بوابة البحث',
            onPressed: onSearch,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: 'المجلدات',
            onPressed: onFolders,
          ),
          IconButton(
            icon: const Icon(Icons.offline_pin_outlined),
            tooltip: 'الملفات المتاحة دون اتصال',
            onPressed: onOfflineFiles,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: onNotifications,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  onLogout();
                case 'delete_account':
                  onDeleteAccount();
                case 'offline':
                  onOfflineFiles();
                case 'profile':
                  onProfile();
                case 'admin':
                  onAdmin();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('معلومات الحساب'),
              ),
              const PopupMenuItem(
                value: 'offline',
                child: Text('الملفات دون اتصال'),
              ),
              if (isAdmin)
                const PopupMenuItem(
                  value: 'admin',
                  child: Text('لوحة الإدارة'),
                ),
              const PopupMenuItem(value: 'logout', child: Text('تسجيل الخروج')),
              const PopupMenuItem(
                value: 'delete_account',
                child: Text('حذف الحساب'),
              ),
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
                    context,
                    label: 'الأحدث أولاً',
                    selected: sort == 'latest',
                    onTap: () => onSortChanged('latest'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _sortChip(
                    context,
                    label: 'الأكثر تحميلاً',
                    selected: sort == 'most_downloaded',
                    onTap: () => onSortChanged('most_downloaded'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: onOpenFilters,
                  tooltip: 'الفلاتر',
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: files.isEmpty
                  ? _buildEmpty()
                  : GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: files.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= files.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final file = files[index];
                        return FileCard(
                          file: file,
                          onTap: () {
                            onOpenFile(file);
                          },
                          onFavorite: () => onFavorite(file),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: canContribute
          ? FloatingActionButton.extended(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file),
              label: const Text('رفع محتوى تعليمي'),
            )
          : null,
    );
  }

  Widget _sortChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : AppTheme.borderColor,
          ),
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
    if (isLoading) {
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
}

class LibraryFilterOptions {
  final List<CatalogItem> categories;
  final List<CatalogItem> materials;

  const LibraryFilterOptions({
    required this.categories,
    required this.materials,
  });
}

class LibraryFilterSheetView extends StatefulWidget {
  final int? currentCategory;
  final int? currentMaterial;
  final int? currentMinRating;
  final Future<LibraryFilterOptions> Function() onLoadOptions;
  final void Function(int? category, int? material, int? rating) onApply;

  const LibraryFilterSheetView({
    super.key,
    this.currentCategory,
    this.currentMaterial,
    this.currentMinRating,
    required this.onLoadOptions,
    required this.onApply,
  });

  @override
  State<LibraryFilterSheetView> createState() => _LibraryFilterSheetViewState();
}

class _LibraryFilterSheetViewState extends State<LibraryFilterSheetView> {
  int? _category;
  int? _material;
  int? _rating;
  List<CatalogItem> _categories = [];
  List<CatalogItem> _materials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _category = widget.currentCategory;
    _material = widget.currentMaterial;
    _rating = widget.currentMinRating;
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final options = await widget.onLoadOptions();
      if (!mounted) return;
      setState(() {
        _categories = options.categories;
        _materials = options.materials;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
              Text(
                'التخصص / الصف',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                )
              else if (_categories.isEmpty)
                const Text('لا توجد تصنيفات')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories
                      .map(
                        (category) => FilterChip(
                          label: Text(category.name),
                          selected: _category == category.id,
                          onSelected: (_) {
                            setState(
                              () => _category = _category == category.id
                                  ? null
                                  : category.id,
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 20),
              Text('المادة', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                )
              else if (_materials.isEmpty)
                const Text('لا توجد مواد')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _materials
                      .map(
                        (material) => FilterChip(
                          label: Text(material.name),
                          selected: _material == material.id,
                          onSelected: (_) {
                            setState(
                              () => _material = _material == material.id
                                  ? null
                                  : material.id,
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      widget.onApply(_category, _material, _rating),
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

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
