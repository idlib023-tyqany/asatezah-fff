import 'package:flutter/material.dart';

import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_service.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';
import 'package:asatezah/features/resource_hub/file_detail/file_detail_screen.dart';

import './favorites_view.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _library = LibraryService();
  List<FileItem> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final favorites = await _library.fetchFavorites();
      if (!mounted) return;
      setState(() => _files = favorites);
    } catch (_) {
      if (!mounted) return;
      setState(() => _files = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeFromFavorites(FileItem file) async {
    final index = _files.indexWhere((item) => item.id == file.id);
    if (index == -1) return;

    // 1. التحديث الفوري المبتكر (Optimistic Update)
    setState(() {
      _files.removeAt(index);
    });

    try {
      await _library.removeFavorite(file.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إزالة "${file.title}" من المفضلة'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      // 2. في حال فشل الطلب، إرجاع العنصر لمكانه المحدد سابقاً
      if (!mounted) return;
      setState(() {
        _files.insert(index, file);
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تعذر إزالة الملف من المفضلة')));
    }
  }

  Future<void> _openFile(FileItem file) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FileDetailScreen(file: file)),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return FavoritesView(
      files: _files,
      isLoading: _loading,
      onRefresh: _load,
      onOpenFile: _openFile,
      onRemoveFromFavorites: _removeFromFavorites,
    );
  }
}
