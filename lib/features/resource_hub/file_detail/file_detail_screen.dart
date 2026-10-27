import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:asatezah/core/network/api_config.dart';
import 'package:asatezah/core/network/api_service.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_service.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';
import 'package:asatezah/features/resource_hub/file_detail/file_detail_view.dart';

class FileDetailScreen extends StatefulWidget {
  final FileItem file;

  const FileDetailScreen({super.key, required this.file});

  @override
  State<FileDetailScreen> createState() => _FileDetailScreenState();
}

class _FileDetailScreenState extends State<FileDetailScreen> {
  late FileItem _file;
  final _library = LibraryService();
  final _comments = CommentService();
  final _offline = OfflineService();

  List<Comment> _commentList = [];
  bool _isFavorite = false;
  bool _isOffline = false;
  bool _isDownloading = false;
  bool _isSubmittingComment = false;
  bool _loadingComments = true;

  final _commentController = TextEditingController();

  String get _fileUrl => '${ApiConfig.baseUrl}/files/${_file.id}/download';

  @override
  void initState() {
    super.initState();
    _file = widget.file;
    _isFavorite = widget.file.isFavorite;
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final offlineStatus = await _offline.isAvailableOffline(_file.id);
    if (!mounted) return;

    setState(() {
      _isOffline = offlineStatus;
    });

    await _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final list = await _comments.fetchComments(_file.id);
      if (!mounted) return;
      setState(() {
        _commentList = list;
        _loadingComments = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingComments = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final previousState = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);

    try {
      if (previousState) {
        await _library.removeFavorite(_file.id);
      } else {
        await _library.addFavorite(_file.id);
      }
      if (!mounted) return;
      _notify(previousState ? 'تمت الإزالة من المفضلة' : 'تمت الإضافة للمفضلة');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFavorite = previousState);
      _notify('حدث خطأ أثناء تحديث المفضلة');
    }
  }

  Future<void> _rate(int value) async {
    try {
      final result = await _library.rate(_file.id, value);
      if (!mounted) return;
      final newAvgRating = (result['avg_rating'] as num?)?.toDouble() ?? _file.stats.avgRating;
      setState(() {
        _file = _file.copyWith(
          myRating: value,
          stats: _file.stats.copyWith(avgRating: newAvgRating),
        );
      });
      _notify('شكراً لتقييمك');
    } catch (_) {
      if (mounted) _notify('تعذّر تسجيل التقييم');
    }
  }

  Future<void> _read() async {
    try {
      final filePath = await _downloadFileInternal();
      if (filePath != null && mounted) {
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done && mounted) {
          _notify('تعذّر فتح الملف، يرجى التأكد من وجود تطبيق يدعم هذا الملف');
        }
      }
    } catch (_) {
      if (mounted) _notify('تعذّر قراءة الملف');
    }
  }

  Future<void> _downloadFile() async {
    final path = await _downloadFileInternal();
    if (path != null && mounted) {
      _notify('تم تحميل الملف بنجاح');
    }
  }

  Future<String?> _downloadFileInternal() async {
    if (_isDownloading) return null;
    setState(() => _isDownloading = true);

    try {
      final savedPath = await _downloadContent(_fileUrl, _file.filename);
      return savedPath;
    } catch (_) {
      if (mounted) _notify('تعذّر تحميل الملف');
      return null;
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<String> _downloadContent(String url, String filename) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final token = ApiService().token;
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      final response = await request.close();
      if (response.statusCode >= 400) {
        throw Exception('Download failed with status ${response.statusCode}');
      }

      final base = await getApplicationDocumentsDirectory();
      final folder = Directory('${base.path}/asatezah_downloads');
      if (!await folder.exists()) await folder.create(recursive: true);

      final file = File('${folder.path}/$filename');

      // كتابة البيانات بشكل تدفقي (Stream) لتفادي استهلاك الذاكرة الكبيرة للملفات الضخمة
      final sink = file.openWrite();
      await response.pipe(sink);
      await sink.close();

      return file.path;
    } finally {
      client.close();
    }
  }

  Future<void> _toggleOffline() async {
    try {
      if (_isOffline) {
        await _offline.removeOffline(_file.id);
        if (!mounted) return;
        setState(() => _isOffline = false);
        _notify('أُزيل من التخزين المحلي');
      } else {
        await _offline.saveForOffline(fileItem: _file, downloadUrl: _fileUrl);
        if (!mounted) return;
        setState(() => _isOffline = true);
        _notify('متاح الآن بدون اتصال بالإنترنت');
      }
    } catch (_) {
      if (mounted) _notify('تعذّرت العملية');
    }
  }

  Future<void> _share() async {
    await SharePlus.instance.share('text' as ShareParams);
  }

  Future<void> _report(String? reason) async {
    try {
      final trimmedReason = reason?.trim();
      await _library.reportFile(
        _file.id,
        trimmedReason == null || trimmedReason.isEmpty ? null : trimmedReason,
      );
      if (!mounted) return;
      _notify('تم إرسال بلاغك بنجاح');
    } catch (_) {
      if (mounted) _notify('تعذّر إرسال البلاغ');
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmittingComment) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmittingComment = true);

    try {
      final comment = await _comments.addComment(_file.id, text);
      _commentController.clear();
      if (!mounted) return;
      setState(() => _commentList = [comment, ..._commentList]);
      _notify('تم إضافة التعليق');
    } catch (_) {
      if (mounted) _notify('تعذّر إضافة التعليق');
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _editComment(Comment comment, String newBody) async {
    if (newBody.trim().isEmpty) return;
    try {
      final updated = await _comments.updateComment(comment.id, newBody.trim());
      if (!mounted) return;
      final list = [..._commentList];
      final index = list.indexWhere((c) => c.id == comment.id);
      if (index != -1) {
        list[index] = updated;
        setState(() => _commentList = list);
      }
      _notify('تم تحديث التعليق');
    } catch (_) {
      if (mounted) _notify('تعذّر تحديث التعليق');
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    try {
      await _comments.deleteComment(comment.id);
      if (!mounted) return;
      setState(() => _commentList = _commentList.where((c) => c.id != comment.id).toList());
      _notify('تم حذف التعليق');
    } catch (_) {
      if (mounted) _notify('تعذّر حذف التعليق');
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return FileDetailView(
      file: _file,
      comments: _commentList,
      isFavorite: _isFavorite,
      isOffline: _isOffline,
      isDownloading: _isDownloading,
      isSubmittingComment: _isSubmittingComment,
      isLoadingComments: _loadingComments,
      commentController: _commentController,
      onToggleFavorite: _toggleFavorite,
      onShare: _share,
      onReport: _report,
      onRate: _rate,
      onRead: _read,
      onDownload: _downloadFile,
      onToggleOffline: _toggleOffline,
      onAddComment: _addComment,
      onEditComment: _editComment,
      onDeleteComment: _deleteComment,
    );
  }
}
