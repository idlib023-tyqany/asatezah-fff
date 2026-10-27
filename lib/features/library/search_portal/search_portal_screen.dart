import 'dart:async';

import 'package:flutter/material.dart';

import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_service.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';
import 'package:asatezah/features/resource_hub/file_detail/file_detail_screen.dart';

import './search_portal_view.dart';

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
  String? _errorMessage;

  Timer? _debounceTimer;
  int _searchRequestId = 0; // لمنع مشكلة Race Condition

  @override
  void initState() {
    super.initState();
    // إشعار الواجهة عند تغير النص لإظهار/إخفاء زر المسح فوراً
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// تنفيذ البحث عند تغير النص مع تأخير لحماية السيرفر
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
          _errorMessage = null;
        });
      }
      return;
    }

    // زيادة معرف الطلب لتتبع آخر طلب تم إرساله فقط
    final currentRequestId = ++_searchRequestId;

    setState(() {
      _searching = true;
      _searched = true;
      _errorMessage = null;
    });

    try {
      final result = await _library.fetchFiles(page: 1, query: trimmedQuery, sort: 'latest');

      // التأكد من أن هذا الطلب هو أحدث طلب تم إرساله
      if (mounted && currentRequestId == _searchRequestId) {
        setState(() {
          _results = result.items;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted && currentRequestId == _searchRequestId) {
        setState(() {
          _results = [];
          _errorMessage = 'حدث خطأ أثناء البحث، يرجى المحاولة لاحقاً';
          _searching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SearchPortalView(
      controller: _controller,
      results: _results,
      isSearching: _searching,
      hasSearched: _searched,
      errorMessage: _errorMessage,
      onChanged: _onSearchChanged,
      onSubmitted: _search,
      onOpenFile: (file) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => FileDetailScreen(file: file)));
      },
    );
  }
}
