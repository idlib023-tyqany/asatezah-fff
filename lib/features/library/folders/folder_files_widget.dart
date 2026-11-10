import 'package:flutter/material.dart';

import 'package:asatezah/core/widgets/file_card.dart';
import 'package:asatezah/features/resource_hub/file_detail/file_detail_widget.dart';

import 'folder_model.dart';
import 'folder_service.dart';

class FolderFilesScreen extends StatefulWidget {
  final FolderItem folder;

  const FolderFilesScreen({super.key, required this.folder});

  @override
  State<FolderFilesScreen> createState() => _FolderFilesScreenState();
}

class _FolderFilesScreenState extends State<FolderFilesScreen> {
  final FolderService _folderService = FolderService();
  late Future<FolderContents> _contentsFuture;

  @override
  void initState() {
    super.initState();
    _contentsFuture = _folderService.fetchFolder(widget.folder.id);
  }

  Future<void> _refresh() async {
    final future = _folderService.fetchFolder(widget.folder.id);
    setState(() => _contentsFuture = future);
    try {
      await future;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذّر تحديث الملفات: $error')));
      }
    }
  }

  Future<void> _openFile(
    BuildContext context,
    int fileIndex,
    FolderContents contents,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FileDetailScreen(file: contents.files[fileIndex]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folder.name)),
      body: FutureBuilder<FolderContents>(
        future: _contentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _FolderError(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final contents = snapshot.data;
          final files = contents?.files ?? const [];
          if (files.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.folder_open_outlined, size: 56),
                  SizedBox(height: 12),
                  Center(child: Text('لا توجد ملفات منشورة في هذا المجلد')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: files.length,
              itemBuilder: (context, index) => FileCard(
                file: files[index],
                onTap: () => _openFile(context, index, contents!),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FolderError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _FolderError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text('تعذّر تحميل الملفات\n$message', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
