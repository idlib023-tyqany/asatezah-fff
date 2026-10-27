import 'package:flutter/material.dart';

import 'package:asatezah/core/widgets/file_type_icon.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';

class UploadView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final bool hasSelectedFile;
  final String? fileName;
  final String? fileNumber;
  final List<CatalogItem> categories;
  final List<CatalogItem> materials;
  final int? categoryId;
  final int? materialId;
  final String? folder;
  final bool isLoadingCatalog;
  final bool isUploading;
  final VoidCallback onPickFile;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<int?> onMaterialChanged;
  final ValueChanged<String?> onFolderChanged;
  final VoidCallback onSubmit;

  const UploadView({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.hasSelectedFile,
    required this.fileName,
    required this.fileNumber,
    required this.categories,
    required this.materials,
    required this.categoryId,
    required this.materialId,
    required this.folder,
    required this.isLoadingCatalog,
    required this.isUploading,
    required this.onPickFile,
    required this.onCategoryChanged,
    required this.onMaterialChanged,
    required this.onFolderChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رفع ملف جديد'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _filePickerCard(context),
              if (fileName != null) ...[const SizedBox(height: 16), _fileNumberCard(context)],
              const SizedBox(height: 20),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'اسم الملف *',
                  hintText: 'مثال: درس الرياضيات - الوحدة الأولى',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اسم الملف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  hintText: 'اكتب ملاحظات أو وصف مختصر عن الملف...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              if (isLoadingCatalog)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                const Text('التخصص / الصف *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: categoryId,
                  hint: const Text('اختر التصنيف'),
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: categories
                      .map((item) => DropdownMenuItem(value: item.id, child: Text(item.name)))
                      .toList(),
                  onChanged: onCategoryChanged,
                  validator: (value) => value == null ? 'يرجى اختيار التصنيف' : null,
                ),
                const SizedBox(height: 16),
                const Text('المادة *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: materialId,
                  hint: Text(categoryId == null ? 'اختر التصنيف أولاً' : 'اختر المادة'),
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: materials
                      .map((item) => DropdownMenuItem(value: item.id, child: Text(item.name)))
                      .toList(),
                  onChanged: categoryId == null ? null : onMaterialChanged,
                  validator: (value) => value == null ? 'يرجى اختيار المادة' : null,
                ),
                const SizedBox(height: 16),
                const Text('المجلد', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: folder,
                  hint: const Text('اختر مكان حفظ الملف'),
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    'الدروس',
                    'الملخصات',
                    'الاختبارات',
                    'الأوراق والأنشطة',
                  ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: onFolderChanged,
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: isUploading ? null : onSubmit,
                  child: isUploading
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

  Widget _filePickerCard(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onPickFile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: !hasSelectedFile ? Colors.grey.shade50 : primaryColor.withValues(alpha: 0.04),
          border: Border.all(
            color: !hasSelectedFile ? Colors.grey.shade300 : primaryColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: !hasSelectedFile
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
                  FileTypeIcon(filename: fileName ?? '', size: 44),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      fileName ?? '',
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

  Widget _fileNumberCard(BuildContext context) {
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
              'رقم الملف المرجعي: ${fileNumber ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
