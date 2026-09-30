import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/file_item.dart';
import '../../services/library_service.dart';
import '../../widgets/file_card.dart';
import '../file_detail/file_detail_screen.dart';

/// بوابة البحث (Portal of Search).
class SearchPortalPage extends StatefulWidget {
  const SearchPortalPage({super.key});

  @override
  State<SearchPortalPage> createState() => _SearchPortalPageState();
}

class _SearchPortalPageState extends State<SearchPortalPage> {
  final _library = LibraryService();
  final _controller = TextEditingController();

  List<FileItem> _results = [];
  bool _searching = false;
  bool _searched = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// تنفيذ البحث عند تغير النص مع تأخير لحماية السيرفر من الطلبات المتكررة
  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          _searched = false;
          _searching = false;
        });
      }
      return;
    }

    setState(() {
      _searching = true;
      _searched = true;
    });

    try {
      final result = await _library.fetchFiles(page: 1, query: trimmedQuery, sort: 'latest');
      if (mounted) {
        setState(() => _results = result.items);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _results = []);
      }
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // حساب عدد الأعمدة بناءً على عرض الشاشة
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(title: const Text('بوابة البحث'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم الملف، التصنيف...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _search('');
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
              child: _buildBodyContent(crossAxisCount),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(int crossAxisCount) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_searched) {
      return const Center(
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

    if (_results.isEmpty) {
      return const Center(
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
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final file = _results[index];
        return FileCard(
          file: file,
          onTap: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => FileDetailScreen(file: file))),
        );
      },
    );
  }
}
