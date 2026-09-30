import 'package:flutter/material.dart';

import '../../models/catalog.dart';
import '../../services/admin_service.dart';

class AdminCatalog extends StatefulWidget {
  const AdminCatalog({super.key});

  @override
  State<AdminCatalog> createState() => _AdminCatalogState();
}

class _AdminCatalogState extends State<AdminCatalog> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _admin = AdminService();

  List<CatalogItem> _categories = [];
  List<CatalogItem> _materials = [];
  final List<String> _folders = ['الدروس', 'الملخصات', 'الاختبارات', 'الأوراق والأنشطة'];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// تحميل البيانات من السيرفر
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final rawCategories = await _admin.fetchCategories();
      final rawMaterials = await _admin.fetchMaterials();

      if (!mounted) return;

      setState(() {
        _categories = rawCategories
            .whereType<Map<String, dynamic>>()
            .map((e) => CatalogItem.fromJson(e))
            .toList();

        _materials = rawMaterials
            .whereType<Map<String, dynamic>>()
            .map((e) => CatalogItem.fromJson(e))
            .toList();

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnackBar('حدث خطأ أثناء تحميل البيانات: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // Operations (Add, Edit, Delete)
  // ==========================================

  Future<void> _addKind(bool isCategory) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    int? selectedGradeId;

    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isCategory ? 'إضافة صف / تخصص' : 'إضافة مادة'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCategory) ...[
                      DropdownButtonFormField<int>(
                        initialValue: selectedGradeId,
                        decoration: const InputDecoration(
                          labelText: 'الصف التابع له *',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories
                            .map(
                              (grade) => DropdownMenuItem(value: grade.id, child: Text(grade.name)),
                            )
                            .toList(),
                        validator: (value) => value == null ? 'يرجى تحديد الصف التابع له' : null,
                        onChanged: (value) => setDialogState(() => selectedGradeId = value),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: isCategory ? 'اسم الصف / التخصص' : 'اسم المادة',
                        hintText: isCategory ? 'مثال: الصف السابع' : 'مثال: العلوم',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      ),
    );

    final name = controller.text.trim();
    controller.dispose();

    if (shouldAdd != true) return;

    try {
      if (isCategory) {
        await _admin.createCategory(name);
      } else {
        await _admin.createMaterial(name, categoryId: selectedGradeId);
      }
      _showSnackBar('تمت الإضافة بنجاح');
      _loadData();
    } catch (e) {
      _showSnackBar('فشلت الإضافة: $e', isError: true);
    }
  }

  Future<void> _editKind(bool isCategory, CatalogItem item) async {
    final controller = TextEditingController(text: item.name);
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الاسم'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (val) =>
                (val == null || val.trim().isEmpty) ? 'لا يمكن إدخال اسم فارغ' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    final name = controller.text.trim();
    controller.dispose();

    if (shouldSave != true || name == item.name) return;

    try {
      if (isCategory) {
        await _admin.updateCategory(item.id, name);
      } else {
        await _admin.updateMaterial(item.id, name);
      }
      _showSnackBar('تم التعديل بنجاح');
      _loadData();
    } catch (e) {
      _showSnackBar('فشل التعديل: $e', isError: true);
    }
  }

  Future<void> _deleteKind(bool isCategory, CatalogItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت تأكد من حذف "${item.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (isCategory) {
        await _admin.deleteCategory(item.id);
      } else {
        await _admin.deleteMaterial(item.id);
      }
      _showSnackBar('تم الحذف بنجاح');
      _loadData();
    } catch (e) {
      _showSnackBar('فشل الحذف: $e', isError: true);
    }
  }

  Future<void> _addFolder() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مجلد'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'مثال: أوراق العمل',
              border: OutlineInputBorder(),
            ),
            validator: (val) =>
                (val == null || val.trim().isEmpty) ? 'يرجى إدخال اسم المجلد' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    final name = controller.text.trim();
    controller.dispose();

    if (shouldAdd == true) {
      setState(() => _folders.add(name));
      _showSnackBar('تمت إضافة المجلد');
    }
  }

  void _onFabPressed() {
    switch (_tabController.index) {
      case 0:
        _addKind(true);
        break;
      case 1:
        _addKind(false);
        break;
      case 2:
        _addFolder();
        break;
    }
  }

  // ==========================================
  // Build Methods
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الصفوف والمواد'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الصفوف / التخصصات'),
            Tab(text: 'المواد حسب الصف'),
            Tab(text: 'المجلدات'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCatalogList(_categories, isCategory: true),
                _buildCatalogList(_materials, isCategory: false),
                _buildFoldersList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCatalogList(List<CatalogItem> items, {required bool isCategory}) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 300,
              child: Center(
                child: Text(
                  'لا توجد عناصر لعرضها',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                isCategory ? Icons.category_outlined : Icons.menu_book_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: (!isCategory && item.categoryName != null)
                ? Text('التخصص / الصف: ${item.categoryName}')
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editKind(isCategory, item),
                  tooltip: 'تعديل',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  onPressed: () => _deleteKind(isCategory, item),
                  tooltip: 'حذف',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoldersList() {
    if (_folders.isEmpty) {
      return const Center(
        child: Text('لا توجد مجلدات', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _folders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: const Icon(Icons.folder_outlined, color: Colors.amber),
          title: Text(_folders[index]),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            onPressed: () => setState(() => _folders.removeAt(index)),
            tooltip: 'حذف المجلد',
          ),
        ),
      ),
    );
  }
}
