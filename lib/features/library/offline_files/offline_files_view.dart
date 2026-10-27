import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class OfflineFilesView extends StatelessWidget {
  const OfflineFilesView({
    required this.files,
    required this.isLoading,
    required this.onRefresh,
    required this.onOpenFile,
    required this.onDelete,
    super.key,
  });

  final List<FileSystemEntity> files;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String path) onOpenFile;
  final Future<void> Function(FileSystemEntity file) onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملفات المحفوظة (أوفلاين)'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : files.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد ملفات محفوظة أوفلاين',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final size = _fileSize(file);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: _fileIcon(file.path),
                          title: Text(
                            p.basename(file.path),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: size.isNotEmpty
                              ? Text(size, style: const TextStyle(fontSize: 12))
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => onDelete(file),
                          ),
                          onTap: () => onOpenFile(file.path),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _fileIcon(String filePath) {
    switch (p.extension(filePath).toLowerCase()) {
      case '.pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case '.docx':
      case '.doc':
        return const Icon(Icons.description, color: Colors.blue);
      case '.png':
      case '.jpg':
      case '.jpeg':
        return const Icon(Icons.image, color: Colors.green);
      default:
        return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  String _fileSize(FileSystemEntity file) {
    try {
      final bytes = file.statSync().size;
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }
}
