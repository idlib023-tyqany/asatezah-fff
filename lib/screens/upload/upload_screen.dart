import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/catalog.dart';
import '../../services/library_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/file_type_icon.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _upload = UploadService();
  final _library = LibraryService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _filePath;
  String? _fileName;
  String? _folder;
  String? _fileNumber;
  int? _categoryId;
  int? _materialId;

  List<CatalogItem> _categories = [];
  List<CatalogItem> _allMaterials = [];
  List<CatalogItem> _filteredMaterials = [];

  bool _loadingCatalog = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      final filters = await _library.fetchFilters();
      if (!mounted) return;
      setState(() {
        _categories = filters.categories;
        _allMaterials = filters.materials;
        _loadingCatalog = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingCatalog = false);
        _notify('تعذّر تحميل قائمة التصنيفات');
      }
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final f = result.files.first;
      setState(() {
        _filePath = f.path;
        _fileName = f.name;
        // وضع اسم الملف تلقائياً في خانة العنوان إذا كانت فارغة
        if (_titleController.text.trim().isEmpty && f.name.contains('.')) {
          _titleController.text = f.name.substring(0, f.name.lastIndexOf('.'));
        }
        // توليد رقم مرجعي محدد للملف
        _fileNumber = 'AS-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      });
    }
  }

  void _onCategoryChanged(int? categoryId) {
    setState(() {
      _categoryId = categoryId;
      _materialId = null;
      if (categoryId == null) {
        _filteredMaterials = [];
      } else {
        // إذا كان موديل CatalogItem يحتوي على parentId فلتر بناءً عليه:
        // _filteredMaterials = _allMaterials.where((m) => m.parentId == categoryId).toList();
        _filteredMaterials = _allMaterials;
      }
    });
  }

  Future<void> _submit() async {
    if (_filePath == null) {
      _notify('يرجى اختيار ملف أولاً');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _uploading = true);

    try {
      await _upload.upload(
        filePath: _filePath!,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        categoryId: _categoryId,
        materialId: _materialId,
        // يمكن إرسال القيم الإضافية للـ API هنا إذا كانت مدعومة:
        // folder: _folder,
        // fileNumber: _fileNumber,
      );

      if (!mounted) return;

      // حفظ الـ Messenger قبل عمل pop لتجنب مشاكل context Async
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(const SnackBar(content: Text('تم رفع الملف وإرساله للمراجعة بنجاح')));
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        _notify('تعذّر رفع الملف، يرجى المحاولة مرة أخرى');
      }
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
      appBar: AppBar(title: const Text('رفع ملف جديد'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _filePickerCard(),
              if (_fileName != null) ...[const SizedBox(height: 16), _fileNumberCard()],
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'اسم الملف *',
                  hintText: 'مثال: درس الرياضيات - الوحدة الأولى',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال اسم الملف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  hintText: 'اكتب ملاحظات أو وصف مختصر عن الملف...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              if (_loadingCatalog)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                const Text('التخصص / الصف *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  hint: const Text('اختر التصنيف'),
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _categories
                      .map((i) => DropdownMenuItem(value: i.id, child: Text(i.name)))
                      .toList(),
                  onChanged: _onCategoryChanged,
                  validator: (v) => v == null ? 'يرجى اختيار التصنيف' : null,
                ),
                const SizedBox(height: 16),
                const Text('المادة *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _materialId,
                  hint: Text(_categoryId == null ? 'اختر التصنيف أولاً' : 'اختر المادة'),
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _filteredMaterials
                      .map((i) => DropdownMenuItem(value: i.id, child: Text(i.name)))
                      .toList(),
                  onChanged: _categoryId == null ? null : (v) => setState(() => _materialId = v),
                  validator: (v) => v == null ? 'يرجى اختيار المادة' : null,
                ),
                const SizedBox(height: 16),
                const Text('المجلد', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _folder,
                  hint: const Text('اختر مكان حفظ الملف'),
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    'الدروس',
                    'الملخصات',
                    'الاختبارات',
                    'الأوراق والأنشطة',
                  ].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (value) => setState(() => _folder = value),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _uploading ? null : _submit,
                  child: _uploading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('إرسال للمراجعة', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filePickerCard() {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _filePath == null ? Colors.grey.shade50 : primaryColor.withValues(alpha: 0.04),
          border: Border.all(
            color: _filePath == null ? Colors.grey.shade300 : primaryColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: _filePath == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 44, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'اختر ملفاً للرفع',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'PDF, Word, Excel, PowerPoint, صور، فيديو',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FileTypeIcon(filename: _fileName ?? '', size: 44),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _fileName ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('اضغط لتغيير الملف', style: TextStyle(fontSize: 11, color: primaryColor)),
                ],
              ),
      ),
    );
  }

  Widget _fileNumberCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.tag, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'رقم الملف المرجعي: ${_fileNumber ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
