import 'package:flutter/material.dart';

import 'folder_files_screen.dart';
import 'folder_model.dart';
import 'folder_service.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('المجلدات')),
      body: FutureBuilder<List<FolderItem>>(
        future: _foldersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _LoadError(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final folders = snapshot.data ?? const <FolderItem>[];
          if (folders.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.folder_off_outlined, size: 56),
                  SizedBox(height: 12),
                  Center(child: Text('لا توجد مجلدات حالياً')),
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
                maxCrossAxisExtent: 240,
                mainAxisExtent: 150,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return _FolderCard(
                  folder: folder,
                  onTap: () => _openFolder(folder),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final FolderItem folder;
  final VoidCallback onTap;

  const _FolderCard({required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.folder_rounded,
                size: 42,
                color: theme.colorScheme.primary,
              ),
              const Spacer(),
              Text(
                folder.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${folder.filesCount} ملف',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _LoadError({required this.message, required this.onRetry});

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
            Text('تعذّر تحميل المجلدات\n$message', textAlign: TextAlign.center),
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
