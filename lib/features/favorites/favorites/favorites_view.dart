import 'package:flutter/material.dart';

import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';
import 'package:asatezah/core/widgets/file_card.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({
    required this.files,
    required this.isLoading,
    required this.onRefresh,
    required this.onOpenFile,
    required this.onRemoveFromFavorites,
    super.key,
  });

  final List<FileItem> files;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Future<void> Function(FileItem file) onOpenFile;
  final Future<void> Function(FileItem file) onRemoveFromFavorites;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: onRefresh,
              child: files.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Icon(Icons.favorite_border, size: 72, color: theme.disabledColor),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد ملفات مفضلة',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.disabledColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'قم بإضافة الملفات إلى المفضلة للوصول إليها بسرعة',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor),
                        ),
                      ],
                    )
                  : GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        return FileCard(
                          file: file,
                          onTap: () => onOpenFile(file),
                          onFavorite: () => onRemoveFromFavorites(file),
                        );
                      },
                    ),
            ),
    );
  }
}
