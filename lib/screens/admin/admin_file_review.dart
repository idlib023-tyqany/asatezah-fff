import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/admin_service.dart';

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

  List<dynamic> _files = [];
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
        _files = result['data'] as List<dynamic>? ?? [];
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

  // حوار نقل الملف إلى تصنيف ومادة جديدين (مع ميزة التخزين المؤقت)
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
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('نقل')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_isTrash && _files.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever_outlined),
              tooltip: 'تفريغ سلة المهملات',
              onPressed: _emptyTrash,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'بحث في الملفات...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _load();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _files.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Text(
                                  'لا توجد ملفات في القائمة',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            itemCount: _files.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final file = _files[index];
                              return _tile(file);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tile(Map<String, dynamic> f) {
    final uploader = f['uploader'];
    final status = f['status'] ?? '';

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withAlpha(20),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.insert_drive_file_outlined, color: Theme.of(context).primaryColor),
      ),
      title: Text(
        f['title'] ?? 'بدون عنوان',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                f['category']?['name'] ?? '',
                f['material']?['name'] ?? '',
                uploader != null ? 'رفع: ${uploader['name'] ?? ''}' : '',
              ].where((s) => s.isNotEmpty).join(' • '),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            _statusBadge(status),
          ],
        ),
      ),
      trailing: _isTrash ? _trashActions(f) : _reviewActions(f),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;

    if (_isTrash) {
      color = Colors.red;
      label = 'في المهملات';
    } else {
      switch (status) {
        case 'published':
          color = Colors.green;
          label = 'منشور';
          break;
        case 'pending':
          color = Colors.orange;
          label = 'قيد المراجعة';
          break;
        case 'rejected':
          color = Colors.red;
          label = 'مرفوض';
          break;
        default:
          color = Colors.grey;
          label = status;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(100), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _reviewActions(Map<String, dynamic> f) {
    final status = f['status'] ?? '';
    final id = f['id'] as int;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'pending') ...[
          IconButton(
            tooltip: 'موافقة ونشر',
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => _action(
              id,
              () => _admin.approveFile(id),
              successMessage: 'تمت الموافقة ونشر الملف',
            ),
          ),
          IconButton(
            tooltip: 'رفض',
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () =>
                _action(id, () => _admin.rejectFile(id), successMessage: 'تم رفض الملف'),
          ),
        ],
        if (status == 'rejected')
          IconButton(
            tooltip: 'إعادة فتح للمراجعة',
            icon: const Icon(Icons.replay, color: Colors.orange),
            onPressed: () => _action(
              id,
              () => _admin.reopenFile(id),
              successMessage: 'تمت إعادة الفتح للمراجعة',
            ),
          ),
        if (status == 'published')
          IconButton(
            tooltip: 'نقل إلى تصنيف/مادة',
            icon: const Icon(Icons.drive_file_move_outlined, color: Colors.blue),
            onPressed: () => _moveDialog(f),
          ),
        IconButton(
          tooltip: 'نقل للسلة المهملات',
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _action(
            id,
            () => _admin.trashFile(id),
            successMessage: 'تم نقل الملف إلى سلة المهملات',
          ),
        ),
      ],
    );
  }

  Widget _trashActions(Map<String, dynamic> f) {
    final id = f['id'] as int;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'استعادة',
          icon: const Icon(Icons.restore, color: Colors.green),
          onPressed: () =>
              _action(id, () => _admin.restoreFile(id), successMessage: 'تمت استعادة الملف بنجاح'),
        ),
        IconButton(
          tooltip: 'حذف نهائي',
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          onPressed: () => _confirmForceDelete(id),
        ),
      ],
    );
  }
}
