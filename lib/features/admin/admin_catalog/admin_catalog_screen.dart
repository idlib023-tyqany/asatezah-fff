import 'package:flutter/material.dart';

import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';
import 'package:asatezah/features/admin/admin_dashboard/admin_dashboard_service.dart';

import './admin_catalog_view.dart';

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
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  isCategory ? Icons.school_outlined : Icons.book_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  isCategory ? 'إضافة صف / تخصص' : 'إضافة مادة جديدة',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCategory) ...[
                      DropdownButtonFormField<int>(
                        initialValue: selectedGradeId,
                        decoration: InputDecoration(
                          labelText: 'الصف التابع له *',
                          prefixIcon: const Icon(Icons.class_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        hintText: isCategory ? 'مثال: الصف السابع' : 'مثال: العلوم العامة',
                        prefixIcon: Icon(
                          isCategory ? Icons.category_outlined : Icons.menu_book_outlined,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.pop(ctx, true);
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_outlined),
            SizedBox(width: 8),
            Text('تعديل الاسم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'الاسم الجديد',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (val) =>
                (val == null || val.trim().isEmpty) ? 'لا يمكن إدخال اسم فارغ' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('حفظ التغييرات'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد الحذف'),
          ],
        ),
        content: Text('هل أنت أثق تماماً من حذف "${item.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف النهائي'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.create_new_folder_outlined, color: Colors.amber),
            SizedBox(width: 8),
            Text('إضافة مجلد جديد'),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'مثال: أوراق العمل والأنشطة',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (val) =>
                (val == null || val.trim().isEmpty) ? 'يرجى إدخال اسم المجلد' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
    return AdminCatalogView(
      tabController: _tabController,
      categories: _categories,
      materials: _materials,
      folders: _folders,
      isLoading: _loading,
      onRefresh: _loadData,
      onAdd: _onFabPressed,
      onEdit: (item, isCategory) => _editKind(isCategory, item),
      onDelete: (item, isCategory) => _deleteKind(isCategory, item),
      onDeleteFolder: (index) {
        setState(() => _folders.removeAt(index));
      },
    );
  }
}
