import 'package:flutter/material.dart';

import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';

class AdminCatalogView extends StatelessWidget {
  const AdminCatalogView({
    required this.tabController,
    required this.categories,
    required this.materials,
    required this.folders,
    required this.isLoading,
    required this.onRefresh,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onDeleteFolder,
    super.key,
  });

  final TabController tabController;
  final List<CatalogItem> categories;
  final List<CatalogItem> materials;
  final List<String> folders;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;
  final void Function(CatalogItem item, bool isCategory) onEdit;
  final void Function(CatalogItem item, bool isCategory) onDelete;
  final ValueChanged<int> onDeleteFolder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الصفوف والمواد والمجلدات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.school_outlined), text: 'الصفوف والتخصصات'),
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'المواد الدراسية'),
            Tab(icon: Icon(Icons.folder_outlined), text: 'المجلدات'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: tabController,
              children: [
                _buildCatalogList(context, categories, isCategory: true),
                _buildCatalogList(context, materials, isCategory: false),
                _buildFoldersList(context),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: Text(
          tabController.index == 0
              ? 'إضافة صف'
              : tabController.index == 1
              ? 'إضافة مادة'
              : 'إضافة مجلد',
        ),
      ),
    );
  }

  Widget _buildCatalogList(
    BuildContext context,
    List<CatalogItem> items, {
    required bool isCategory,
  }) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCategory ? Icons.school_outlined : Icons.menu_book_outlined,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isCategory ? 'لا توجد صفوف أو تخصصات مضافة' : 'لا توجد مواد دراسية مضافة',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            elevation: 1.5,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCategory ? Icons.school_outlined : Icons.menu_book_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: (!isCategory && item.categoryName != null)
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.class_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'التخصص / الصف: ${item.categoryName}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => onEdit(item, isCategory),
                    tooltip: 'تعديل',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                    onPressed: () => onDelete(item, isCategory),
                    tooltip: 'حذف',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoldersList(BuildContext context) {
    if (folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('لا توجد مجلدات حالية', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: folders.length,
      itemBuilder: (context, index) => Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          leading: const Icon(Icons.folder_rounded, color: Colors.amber, size: 32),
          title: Text(folders[index], style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            onPressed: () => onDeleteFolder(index),
            tooltip: 'حذف المجلد',
          ),
        ),
      ),
    );
  }
}
