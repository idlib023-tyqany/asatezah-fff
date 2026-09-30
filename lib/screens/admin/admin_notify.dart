import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/library_service.dart';
import '../../models/catalog.dart';

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

  final Set<CatalogItem> _selectedCategories = {};
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
      if (mounted) {
        setState(() {
          _availableCategories = catalog.categories;
        });
      }
    } catch (_) {
      _notify('تعذر تحميل قائمة التخصصات والصفوف');
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _confirmAndSend() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _notify('يرجى كتابة العنوان ونص الإشعار');
      return;
    }

    if (!_toAll && _selectedCategories.isEmpty) {
      _notify('يرجى اختيار تخصص واحد على الأقل');
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
              : 'سيتم إرسال الإشعار إلى ${_selectedCategories.length} تخصص/صف مختار.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إرسال الآن')),
        ],
      ),
    );

    if (confirm != true) return;

    _send(title, body);
  }

  Future<void> _send(String title, String body) async {
    setState(() => _sending = true);
    try {
      if (_toAll) {
        await _admin.sendToAll(title, body);
      } else {
        // إرسال متوازي للتخصصات المحددة
        await Future.wait(
          _selectedCategories.map((cat) => _admin.sendToSpecialization(cat.name, title, body)),
        );
      }

      _titleController.clear();
      _bodyController.clear();
      setState(() => _selectedCategories.clear());

      if (mounted) _notify('تم إرسال الإشعار بنجاح');
    } catch (_) {
      _notify('تعذّر إرسال الإشعار، يرجى المحاولة لاحقاً');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _notify(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إرسال إشعار')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('لجميع المستخدمين'),
                icon: Icon(Icons.people_alt_outlined),
              ),
              ButtonSegment(
                value: false,
                label: Text('حسب التخصص'),
                icon: Icon(Icons.category_outlined),
              ),
            ],
            selected: {_toAll},
            onSelectionChanged: (s) => setState(() => _toAll = s.first),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان الإشعار',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bodyController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'نص الإشعار',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          if (!_toAll) ...[
            const SizedBox(height: 20),
            Text('اختر التخصصات والصفوف المستهدفة:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            if (_loadingCategories)
              const Center(child: CircularProgressIndicator())
            else if (_availableCategories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('لا توجد تخصصات مضافة بعد.', style: TextStyle(color: Colors.grey)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCategories.map((item) {
                  final isSelected = _selectedCategories.contains(item);
                  return FilterChip(
                    label: Text(item.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(item);
                        } else {
                          _selectedCategories.remove(item);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _sending ? null : _confirmAndSend,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_sending ? 'جاري الإرسال...' : 'إرسال الإشعار'),
            ),
          ),
        ],
      ),
    );
  }
}
