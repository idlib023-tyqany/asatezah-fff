import 'package:flutter/material.dart';

import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';
import 'package:asatezah/core/widgets/file_card.dart';

class SearchPortalView extends StatelessWidget {
  const SearchPortalView({
    required this.controller,
    required this.results,
    required this.isSearching,
    required this.hasSearched,
    required this.errorMessage,
    required this.onChanged,
    required this.onSubmitted,
    required this.onOpenFile,
    super.key,
  });

  final TextEditingController controller;
  final List<FileItem> results;
  final bool isSearching;
  final bool hasSearched;
  final String? errorMessage;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<FileItem> onOpenFile;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = MediaQuery.of(context).size.width > 600 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(title: const Text('بوابة البحث'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم الملف، التصنيف...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          onSubmitted('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildResults(crossAxisCount),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(int crossAxisCount) {
    if (isSearching) {
      return const Center(key: ValueKey('loading'), child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(errorMessage!, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    if (!hasSearched) {
      return const Center(
        key: ValueKey('initial'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('ابحث عن الملفات بسهولة', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    if (results.isEmpty) {
      return const Center(
        key: ValueKey('empty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.find_in_page_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('لا توجد نتائج مطابقة لبحثك', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return GridView.builder(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final file = results[index];
        return FileCard(file: file, onTap: () => onOpenFile(file));
      },
    );
  }
}
