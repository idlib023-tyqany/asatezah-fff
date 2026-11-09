import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/app_models.dart';
import '../files/file_details_screen.dart';

class FolderExplorerScreen extends StatefulWidget {
  final int? folderId;
  final String title;

  const FolderExplorerScreen({
    super.key,
    this.folderId,
    this.title = 'المجلد الرئيسي (الشاشة الرئيسية)',
  });

  @override
  State<FolderExplorerScreen> createState() => _FolderExplorerScreenState();
}

class _FolderExplorerScreenState extends State<FolderExplorerScreen> {
  bool _isLoading = true;
  String? _error;
  List<FolderModel> _subfolders = [];
  List<FileModel> _files = [];
  String _currentTitle = '';

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
    _loadFolder();
  }

  Future<void> _loadFolder() async {
    setState(() => _isLoading = true);
    try {
      final data = widget.folderId == null
          ? await ApiService.getRootFolder()
          : await ApiService.getFolder(widget.folderId!);

      final subList = (data['subfolders'] as List? ?? [])
          .map((item) => FolderModel.fromJson(item))
          .toList();

      final fileList = (data['files'] as List? ?? [])
          .map((item) => FileModel.fromJson(item))
          .toList();

      setState(() {
        _subfolders = subList;
        _files = fileList;
        _currentTitle = data['current']?['name'] ?? widget.title;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تأكد من تشغيل سيرفر لارافيل (php artisan serve)';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadFolder,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.amber),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _loadFolder, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_subfolders.isNotEmpty) ...[
                      const Text('المجلدات التابعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _subfolders.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.3,
                        ),
                        itemBuilder: (ctx, i) {
                          final f = _subfolders[i];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FolderExplorerScreen(folderId: f.id, title: f.name),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colorScheme.outlineVariant),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder_rounded, size: 36, color: colorScheme.primary),
                                  const SizedBox(height: 6),
                                  Text(
                                    f.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_files.isNotEmpty) ...[
                      const Text('الملفات التعليمية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _files.length,
                        itemBuilder: (ctx, i) {
                          final file = _files[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: colorScheme.outlineVariant),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                              title: Text(file.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('ID: ${file.id} • ${file.fileSize}'),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => FileDetailsScreen(file: file)),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                    if (_subfolders.isEmpty && _files.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Text('لا توجد ملفات أو مجلدات داخل هذا الصف حالياً'),
                        ),
                      ),
                  ],
                ),
    );
  }
}
