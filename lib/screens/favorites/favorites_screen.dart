import 'package:flutter/material.dart';

import '../../models/file_item.dart';
import '../../services/library_service.dart';
import '../../widgets/file_card.dart';
import '../file_detail/file_detail_screen.dart';

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
    // 1. التحديث الفوري للواجهة
    setState(() {
      _files.removeWhere((item) => item.id == file.id);
    });

    try {
      await _library.removeFavorite(file.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إزالة "${file.title}" من المفضلة'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      // في حال فشل الاتصال، نعيد الملف للقائمة
      if (!mounted) return;
      setState(() {
        _files.add(file);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تعذر إزالة الملف من المفضلة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _files.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Icon(
                          Icons.favorite_border,
                          size: 72,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد ملفات مفضلة',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Theme.of(context).disabledColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'قم بإضافة الملفات إلى المفضلة للوصول إليها بسرعة',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Theme.of(context).disabledColor),
                        ),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _files.length,
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        return FileCard(
                          file: file,
                          onTap: () async {
                            await Navigator.of(
                              context,
                            ).push(MaterialPageRoute(builder: (_) => FileDetailScreen(file: file)));
                            _load();
                          },
                          onFavorite: () => _removeFromFavorites(file),
                        );
                      },
                    ),
            ),
    );
  }
}
