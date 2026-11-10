import 'package:flutter/material.dart';

import 'folder_model.dart';

class FoldersView extends StatelessWidget {
  const FoldersView({
    required this.foldersFuture,
    required this.onRefresh,
    required this.onOpenFolder,
    super.key,
  });

  final Future<List<FolderItem>> foldersFuture;
  final Future<void> Function() onRefresh;
  final ValueChanged<FolderItem> onOpenFolder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المجلدات')),
      body: FutureBuilder<List<FolderItem>>(
        future: foldersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _LoadError(
              message: snapshot.error.toString(),
              onRetry: onRefresh,
            );
          }

          final folders = snapshot.data ?? const <FolderItem>[];
          if (folders.isEmpty) {
            return RefreshIndicator(
              onRefresh: onRefresh,
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
            onRefresh: onRefresh,
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
                  onTap: () => onOpenFolder(folder),
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
  const _FolderCard({required this.folder, required this.onTap});

  final FolderItem folder;
  final VoidCallback onTap;

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
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

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
