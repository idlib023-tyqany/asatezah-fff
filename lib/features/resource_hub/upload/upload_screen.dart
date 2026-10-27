import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_service.dart';
import 'package:asatezah/features/resource_hub/upload/upload_view.dart';

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
    final files = await FilePicker.pickFiles(type: FileType.any);

    if (files.isNotEmpty) {
      final f = files.first;
      setState(() {
        _filePath = f.path;
        _fileName = f.name;

        // استخراج اسم الملف بدون الامتداد
        if (_titleController.text.trim().isEmpty && f.name.contains('.')) {
          _titleController.text = f.name.substring(0, f.name.lastIndexOf('.'));
        }

        // توليد رقم مرجعي محدد للملف
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(6);
        _fileNumber = 'AS-$timestamp';
      });
    }
  }

  void _onCategoryChanged(int? categoryId) {
    setState(() {
      _categoryId = categoryId;
      _materialId = null; // إعادة ضبط المادة المختارة
      if (categoryId == null) {
        _filteredMaterials = [];
      } else {
        _filteredMaterials = List.from(_allMaterials);
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
      );

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم رفع الملف وإرساله للمراجعة بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        _notify('تعذّر رفع الملف، يرجى المحاولة مرة أخرى');
      }
    }
  }

  void _notify(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return UploadView(
      formKey: _formKey,
      titleController: _titleController,
      descriptionController: _descController,
      hasSelectedFile: _filePath != null,
      fileName: _fileName,
      fileNumber: _fileNumber,
      categories: _categories,
      materials: _filteredMaterials,
      categoryId: _categoryId,
      materialId: _materialId,
      folder: _folder,
      isLoadingCatalog: _loadingCatalog,
      isUploading: _uploading,
      onPickFile: _pickFile,
      onCategoryChanged: _onCategoryChanged,
      onMaterialChanged: (value) => setState(() => _materialId = value),
      onFolderChanged: (value) => setState(() => _folder = value),
      onSubmit: _submit,
    );
  }
}
