import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'package:asatezah/core/network/api_config.dart';
import 'package:asatezah/features/auth/auth_service.dart';
import 'package:asatezah/features/auth/login/login_widget.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_service.dart';

import 'file_detail_view.dart';

class FileDetailScreen extends StatefulWidget {
  const FileDetailScreen({required this.file, super.key});

  final FileItem file;

  @override
  State<FileDetailScreen> createState() => _FileDetailScreenState();
}

class _FileDetailScreenState extends State<FileDetailScreen> {
  final _library = LibraryService();
  final _comments = CommentService();
  final _offline = OfflineService();
  final _auth = AuthService();
  final _commentController = TextEditingController();

  late FileItem _file;
  List<Comment> _commentList = [];
  bool _isFavorite = false;
  bool _isOffline = false;
  bool _isDownloading = false;
  bool _isSubmittingComment = false;
  bool _isLoadingComments = true;

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
    try {
      final isOffline = await _offline.isAvailableOffline(_file.id);
      if (mounted) setState(() => _isOffline = isOffline);
    } catch (_) {
      if (mounted) _notify('تعذّر التحقق من الملفات المحفوظة');
    }

    await _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _comments.fetchComments(_file.id);
      if (mounted) setState(() => _commentList = comments);
    } catch (_) {
      if (mounted) _notify('تعذّر تحميل التعليقات');
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final wasFavorite = _isFavorite;
    setState(() => _isFavorite = !wasFavorite);

    try {
      if (wasFavorite) {
        await _library.removeFavorite(_file.id);
      } else {
        await _library.addFavorite(_file.id);
      }

      if (!mounted) return;
      setState(() {
        _file = _file.copyWith(
          isFavorite: !wasFavorite,
          stats: _file.stats.copyWith(
            favoritesCount:
                (_file.stats.favoritesCount + (wasFavorite ? -1 : 1)).clamp(
                  0,
                  1 << 31,
                ),
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFavorite = wasFavorite);
      _notify('تعذّر تحديث المفضلة');
    }
  }

  Future<void> _rate(int value) async {
    try {
      final result = await _library.rate(_file.id, value);
      if (!mounted) return;
      final average = (result['avg_rating'] as num?)?.toDouble();
      setState(() {
        _file = _file.copyWith(
          myRating: value,
          stats: _file.stats.copyWith(avgRating: average),
        );
      });
      _notify('شكراً لتقييمك');
    } catch (_) {
      if (mounted) _notify('تعذّر تسجيل التقييم');
    }
  }

  Future<void> _read() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      final files = await _offline.getOfflineFiles();
      final savedFile = files.where((file) => file.id == _file.id).firstOrNull;
      final localPath =
          savedFile?.localPath ??
          (await _offline.saveForOffline(
            fileItem: _file,
            downloadUrl: _fileUrl,
          )).path;
      final result = await OpenFilex.open(localPath);
      if (result.type != ResultType.done && mounted) {
        _notify('تعذّر فتح الملف على هذا الجهاز');
      }
    } catch (_) {
      if (mounted) _notify('تعذّر قراءة الملف');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<bool> _confirmLogin() async {
    if (_auth.isAuthenticated) return true;

    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الدخول مطلوب'),
        content: const Text('سجّل الدخول للمتابعة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );

    if (shouldLogin == true && mounted) {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
    return false;
  }

  Future<void> _downloadFile() async {
    if (!await _confirmLogin() || _isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      await _offline.saveForOffline(fileItem: _file, downloadUrl: _fileUrl);
      if (mounted) _notify('تم تحميل الملف وحفظه بنجاح');
    } catch (_) {
      if (mounted) _notify('تعذّر تحميل الملف، يرجى المحاولة لاحقاً');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _toggleOffline() async {
    if (!await _confirmLogin()) return;

    try {
      if (_isOffline) {
        await _offline.removeOffline(_file.id);
      } else {
        await _offline.saveForOffline(fileItem: _file, downloadUrl: _fileUrl);
      }
      if (!mounted) return;
      setState(() => _isOffline = !_isOffline);
      _notify(
        _isOffline ? 'الملف متاح دون اتصال' : 'أُزيل الملف من التخزين المحلي',
      );
    } catch (_) {
      if (mounted) _notify('تعذّر تحديث التخزين دون اتصال');
    }
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(text: '${_file.title}\n$_fileUrl'),
    );
  }

  Future<void> _report(String? reason) async {
    try {
      await _library.reportFile(_file.id, reason);
      if (mounted) _notify('تم إرسال البلاغ');
    } catch (_) {
      if (mounted) _notify('تعذّر إرسال البلاغ');
    }
  }

  Future<void> _addComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty || _isSubmittingComment) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmittingComment = true);
    try {
      final comment = await _comments.addComment(_file.id, body);
      if (!mounted) return;
      _commentController.clear();
      setState(() => _commentList = [comment, ..._commentList]);
    } catch (_) {
      if (mounted) _notify('تعذّر إضافة التعليق');
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _editComment(Comment comment, String body) async {
    try {
      final updated = await _comments.updateComment(comment.id, body);
      if (!mounted) return;
      setState(() {
        final index = _commentList.indexWhere((item) => item.id == comment.id);
        if (index >= 0) _commentList[index] = updated;
      });
    } catch (_) {
      if (mounted) _notify('تعذّر تحديث التعليق');
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    try {
      await _comments.deleteComment(comment.id);
      if (!mounted) return;
      setState(() {
        _commentList.removeWhere((item) => item.id == comment.id);
      });
    } catch (_) {
      if (mounted) _notify('تعذّر حذف التعليق');
    }
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
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
      isLoadingComments: _isLoadingComments,
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
