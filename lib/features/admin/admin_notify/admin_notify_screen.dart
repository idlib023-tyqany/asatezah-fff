import 'package:flutter/material.dart';

import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';
import 'package:asatezah/features/admin/admin_dashboard/admin_dashboard_service.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_service.dart';

import './admin_notify_view.dart';

class AdminNotify extends StatefulWidget {
  const AdminNotify({super.key});

  @override
  State<AdminNotify> createState() => _AdminNotifyState();
}

class _AdminNotifyState extends State<AdminNotify> {
  final _admin = AdminService();
  final _library = LibraryService();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  // تخزين معرفات التخصصات المختارة تجنباً لمشاكل Equals/HashCode في Model
  final Set<int> _selectedCategoryIds = {};
  List<CatalogItem> _availableCategories = [];

  bool _loadingCategories = false;
  bool _toAll = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final catalog = await _library.fetchFilters();
      if (!mounted) return;
      setState(() {
        _availableCategories = catalog.categories;
      });
    } catch (_) {
      _notify('تعذر تحميل قائمة التخصصات والصفوف', isError: true);
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _confirmAndSend() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _notify('يرجى كتابة العنوان ونص الإشعار', isError: true);
      return;
    }

    if (!_toAll && _selectedCategoryIds.isEmpty) {
      _notify('يرجى اختيار تخصص واحد على الأقل', isError: true);
      return;
    }

    // حوار التأكيد قبل الإرسال الفعلي
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الإرسال'),
        content: Text(
          _toAll
              ? 'هل أنت تأكد من إرسال هذا الإشعار لجميع المستخدمين؟'
              : 'سيتم إرسال الإشعار إلى ${_selectedCategoryIds.length} تخصص/صف مختار.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إرسال الآن')),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    _send(title, body);
  }

  Future<void> _send(String title, String body) async {
    setState(() => _sending = true);
    try {
      if (_toAll) {
        await _admin.sendToAll(title, body);
      } else {
        // تحضير قائمة أسباب/أسماء التخصصات المحددة
        final selectedNames = _availableCategories
            .where((cat) => _selectedCategoryIds.contains(cat.id))
            .map((cat) => cat.name);

        await Future.wait(
          selectedNames.map((name) => _admin.sendToSpecialization(name, title, body)),
        );
      }

      if (!mounted) return;

      _titleController.clear();
      _bodyController.clear();
      setState(() => _selectedCategoryIds.clear());

      _notify('تم إرسال الإشعار بنجاح');
    } catch (_) {
      _notify('تعذّر إرسال الإشعار، يرجى المحاولة لاحقاً', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _notify(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // اختيار/إلغاء اختيار الجميع
  void _toggleSelectAll(bool select) {
    setState(() {
      if (select) {
        _selectedCategoryIds.addAll(_availableCategories.map((c) => c.id));
      } else {
        _selectedCategoryIds.clear();
      }
    });
  }

  void _toggleCategory(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedCategoryIds.add(id);
      } else {
        _selectedCategoryIds.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminNotifyView(
      titleController: _titleController,
      bodyController: _bodyController,
      categories: _availableCategories,
      selectedCategoryIds: _selectedCategoryIds,
      toAll: _toAll,
      isLoadingCategories: _loadingCategories,
      isSending: _sending,
      onAudienceChanged: (toAll) => setState(() => _toAll = toAll),
      onToggleSelectAll: _toggleSelectAll,
      onToggleCategory: _toggleCategory,
      onSend: _confirmAndSend,
    );
  }
}
