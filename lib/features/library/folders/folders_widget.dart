import 'package:flutter/material.dart';

import 'folder_files_widget.dart';
import 'folder_model.dart';
import 'folder_service.dart';
import 'folders_view.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final FolderService _folderService = FolderService();
  late Future<List<FolderItem>> _foldersFuture;

  @override
  void initState() {
    super.initState();
    _foldersFuture = _folderService.fetchFolders();
  }

  Future<void> _refresh() async {
    final future = _folderService.fetchFolders();
    setState(() => _foldersFuture = future);
    try {
      await future;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذّر تحديث المجلدات: $error')));
      }
    }
  }

  Future<void> _openFolder(FolderItem folder) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FolderFilesScreen(folder: folder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FoldersView(
      foldersFuture: _foldersFuture,
      onRefresh: _refresh,
      onOpenFolder: _openFolder,
    );
  }
}
