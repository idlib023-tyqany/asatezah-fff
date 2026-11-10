import 'package:flutter/material.dart';

import '../teacher_file_details/teacher_file_details_widget.dart';
import 'folder_explorer_model.dart';
import 'folder_explorer_service.dart';
import 'folder_explorer_view.dart';
import '../teacher_file_details/teacher_file_details_model.dart';

class FolderExplorerWidget extends StatefulWidget {
  const FolderExplorerWidget({
    this.folderId,
    this.title = 'المجلد الرئيسي (الشاشة الرئيسية)',
    super.key,
  });

  final int? folderId;
  final String title;

  @override
  State<FolderExplorerWidget> createState() => _FolderExplorerWidgetState();
}

class _FolderExplorerWidgetState extends State<FolderExplorerWidget> {
  final FolderExplorerService _service = FolderExplorerService();
  bool _isLoading = true;
  String? _error;
  String _title = '';
  List<FolderModel> _subfolders = const [];
  List<TeacherFileModel> _files = const [];

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _loadFolder();
  }

  Future<void> _loadFolder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final listing = widget.folderId == null
          ? await _service.loadRoot()
          : await _service.loadFolder(widget.folderId!);
      if (!mounted) return;
      setState(() {
        _subfolders = listing.subfolders;
        _files = listing.files;
        _title = listing.title.isEmpty ? widget.title : listing.title;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  void _openFolder(FolderModel folder) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FolderExplorerWidget(folderId: folder.id, title: folder.name),
      ),
    );
  }

  void _openFile(TeacherFileModel file) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherFileDetailsWidget(file: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FolderExplorerView(
      title: _title,
      isLoading: _isLoading,
      error: _error,
      subfolders: _subfolders,
      files: _files,
      onRefresh: _loadFolder,
      onOpenFolder: _openFolder,
      onOpenFile: _openFile,
    );
  }
}
