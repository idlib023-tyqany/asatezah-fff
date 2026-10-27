import 'dart:async';

import 'package:flutter/material.dart';

import 'package:asatezah/features/admin/admin_dashboard/admin_dashboard_service.dart';
import './file_review_view.dart';

class AdminFileReview extends StatefulWidget {
  final String status;
  final String title;

  const AdminFileReview({super.key, required this.status, required this.title});

  @override
  State<AdminFileReview> createState() => _AdminFileReviewState();
}

class _AdminFileReviewState extends State<AdminFileReview> {
  final _admin = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _files = [];
  List<Map<String, dynamic>>? _cachedCategories;
  List<Map<String, dynamic>>? _cachedMaterials;

  bool _loading = true;
  bool _isTrash = false;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _isTrash = widget.status == 'trashed';
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// تحميل الملفات مع إمكانية البحث
  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final result = await _admin.fetchFiles(
        status: widget.status,
        q: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (!mounted) return;
      setState(() {
        _files = (result['data'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// البحث مع التأخير اللحظي لتخفيف الضغط على السيرفر (Debounce)
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim());
      _load();
    });
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

  Future<void> _action(int id, Future<void> Function() fn, {String? successMessage}) async {
    try {
      await fn();
      if (!mounted) return;
      if (successMessage != null) _showSnackBar(successMessage);
      _load();
    } catch (_) {
      _showSnackBar('تعذّرت العملية، يرجى المحاولة لاحقاً', isError: true);
    }
  }

  // تفريغ السلة بالكامل
  Future<void> _emptyTrash() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تفريغ سلة المهملات'),
        content: const Text('هل أنت تأكد من حذف جميع الملفات الموجودة في السلة نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تفريغ الكل'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _admin.emptyTrash();
        if (mounted) {
          _showSnackBar('تم تفريغ سلة المهملات بنجاح');
          _load();
        }
      } catch (_) {
        _showSnackBar('فشل تفريغ سلة المهملات', isError: true);
      }
    }
  }

  // حوار تأكيد الحذف النهائي
  Future<void> _confirmForceDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف نهائي'),
        content: const Text(
          'هل أنت تأكد من حذف هذا الملف نهائياً؟ لا يمكن الاسترجاع بعد هذه الخطوة.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _action(id, () => _admin.forceDeleteFile(id), successMessage: 'تم الحذف النهائي بنجاح');
    }
  }

  // حوار نقل الملف إلى تصنيف ومادة جديدين
  Future<void> _moveDialog(Map<String, dynamic> file) async {
    try {
      if (_cachedCategories == null || _cachedMaterials == null) {
        final rawCategories = await _admin.fetchCategories();
        final rawMaterials = await _admin.fetchMaterials();

        _cachedCategories = rawCategories.whereType<Map<String, dynamic>>().toList();
        _cachedMaterials = rawMaterials.whereType<Map<String, dynamic>>().toList();
      }

      if (!mounted) return;

      int? selectedCategoryId = file['category']?['id'] as int?;
      int? selectedMaterialId = file['material']?['id'] as int?;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredMaterials = selectedCategoryId == null
                ? _cachedMaterials!
                : _cachedMaterials!.where((m) => m['category_id'] == selectedCategoryId).toList();

            final validMaterialId = filteredMaterials.any((m) => m['id'] == selectedMaterialId)
                ? selectedMaterialId
                : null;

            return AlertDialog(
              title: const Text('نقل الملف'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'اختر الصف / التخصص',
                        border: OutlineInputBorder(),
                      ),
                      items: _cachedCategories!
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text(c['name']?.toString() ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedCategoryId = val;
                          selectedMaterialId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: validMaterialId,
                      decoration: const InputDecoration(
                        labelText: 'اختر المادة',
                        border: OutlineInputBorder(),
                      ),
                      items: filteredMaterials
                          .map(
                            (m) => DropdownMenuItem<int>(
                              value: m['id'] as int,
                              child: Text(m['name']?.toString() ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedMaterialId = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                FilledButton(
                  onPressed: (selectedCategoryId != null && selectedMaterialId != null)
                      ? () => Navigator.pop(ctx, true)
                      : null,
                  child: const Text('نقل'),
                ),
              ],
            );
          },
        ),
      );

      if (confirm == true && selectedCategoryId != null && selectedMaterialId != null) {
        await _action(
          file['id'],
          () => _admin.moveFile(
            file['id'],
            categoryId: selectedCategoryId,
            materialId: selectedMaterialId,
          ),
          successMessage: 'تم نقل الملف بنجاح',
        );
      }
    } catch (_) {
      _showSnackBar('تعذر تحميل التصنيفات والمواد', isError: true);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    _load();
  }

  void _onAction(Map<String, dynamic> file, AdminFileReviewAction action) {
    final id = file['id'] as int;
    switch (action) {
      case AdminFileReviewAction.approve:
        _action(id, () => _admin.approveFile(id), successMessage: '��� �������� ���� �����');
      case AdminFileReviewAction.reject:
        _action(id, () => _admin.rejectFile(id), successMessage: '�� ��� �����');
      case AdminFileReviewAction.reopen:
        _action(id, () => _admin.reopenFile(id), successMessage: '��� ����� ����� ��������');
      case AdminFileReviewAction.move:
        _moveDialog(file);
      case AdminFileReviewAction.trash:
        _action(id, () => _admin.trashFile(id), successMessage: '�� ��� ����� ��� ��� ��������');
      case AdminFileReviewAction.restore:
        _action(id, () => _admin.restoreFile(id), successMessage: '��� ������� ����� �����');
      case AdminFileReviewAction.forceDelete:
        _confirmForceDelete(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminFileReviewView(
      title: widget.title,
      isTrash: _isTrash,
      files: _files,
      isLoading: _loading,
      searchController: _searchController,
      onSearchChanged: _onSearchChanged,
      onClearSearch: _clearSearch,
      onRefresh: _load,
      onEmptyTrash: _emptyTrash,
      onAction: _onAction,
    );
  }
}
