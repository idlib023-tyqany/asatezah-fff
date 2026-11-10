import 'package:flutter/material.dart';

import 'folder_explorer_model.dart';
import '../teacher_file_details/teacher_file_details_model.dart';

class FolderExplorerView extends StatelessWidget {
  const FolderExplorerView({
    required this.title,
    required this.isLoading,
    required this.error,
    required this.subfolders,
    required this.files,
    required this.onRefresh,
    required this.onOpenFolder,
    required this.onOpenFile,
    super.key,
  });

  final String title;
  final bool isLoading;
  final String? error;
  final List<FolderModel> subfolders;
  final List<TeacherFileModel> files;
  final VoidCallback onRefresh;
  final ValueChanged<FolderModel> onOpenFolder;
  final ValueChanged<TeacherFileModel> onOpenFile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: onRefresh,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 12),
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: onRefresh,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (subfolders.isNotEmpty) ...[
                  const Text(
                    'المجلدات التابعة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subfolders.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.3,
                        ),
                    itemBuilder: (context, index) {
                      final folder = subfolders[index];
                      return InkWell(
                        onTap: () => onOpenFolder(folder),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_rounded,
                                size: 36,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                folder.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                if (files.isNotEmpty) ...[
                  const Text(
                    'الملفات التعليمية',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...files.map(
                    (file) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.red,
                        ),
                        title: Text(
                          file.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text('ID: ${file.id} • ${file.fileSize}'),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                        ),
                        onTap: () => onOpenFile(file),
                      ),
                    ),
                  ),
                ],
                if (subfolders.isEmpty && files.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'لا توجد ملفات أو مجلدات داخل هذا الصف حالياً',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
