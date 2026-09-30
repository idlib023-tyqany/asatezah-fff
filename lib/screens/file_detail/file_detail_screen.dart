import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/api_config.dart';
import '../../models/comment.dart';
import '../../models/file_item.dart';
import '../../services/api_service.dart';
import '../../services/comment_service.dart';
import '../../services/library_service.dart';
import '../../services/offline_service.dart';
import '../../widgets/file_type_icon.dart';

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
      _notify('تعذّر تسجيل التقييم');
    }
  }

  Future<void> _read() async {
    try {
      final filePath = await _downloadFileInternal();
      if (filePath != null) {
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done) {
          _notify('تعذّر فتح الملف، يرجى التأكد من وجود تطبيق يدعم هذا الملف');
        }
      }
    } catch (_) {
      _notify('تعذّر قراءة الملف');
    }
  }

  Future<void> _downloadFile() async {
    final path = await _downloadFileInternal();
    if (path != null) {
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
      _notify('تعذّر تحميل الملف');
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
      final bytes = await _collectBytes(response);

      final base = await getApplicationDocumentsDirectory();
      final folder = Directory('${base.path}/asatezah_downloads');
      if (!await folder.exists()) await folder.create(recursive: true);

      final file = File('${folder.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } finally {
      client.close();
    }
  }

  Future<Uint8List> _collectBytes(HttpClientResponse response) async {
    final builder = BytesBuilder();
    await for (final chunk in response) {
      builder.add(chunk);
    }
    return builder.takeBytes();
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
      _notify('تعذّرت العملية');
    }
  }

  Future<void> _share() async {
    // ✅ التحديث للتوافق مع الإصدار الأحدث من share_plus
    final text = '${_file.title}\nمن تطبيق أساتذة - المكتبة الرقمية\n$_fileUrl';
    await Share.share(text);
  }

  Future<void> _report() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _ReportDialog(),
    );
    if (reason == null) return;
    try {
      await _library.reportFile(_file.id, reason.trim().isEmpty ? null : reason.trim());
      _notify('تم إرسال بلاغك بنجاح');
    } catch (_) {
      _notify('تعذّر إرسال البلاغ');
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
      _notify('تعذّر إضافة التعليق');
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _editComment(Comment comment) async {
    final controller = TextEditingController(text: comment.body);
    final newBody = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل التعليق'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newBody == null || newBody.trim().isEmpty) return;

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
      _notify('تعذّر تحديث التعليق');
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التعليق'),
        content: const Text('هل أنت تأكد من رغبتك في حذف هذا التعليق؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _comments.deleteComment(comment.id);
      if (!mounted) return;
      setState(() => _commentList = _commentList.where((c) => c.id != comment.id).toList());
      _notify('تم حذف التعليق');
    } catch (_) {
      _notify('تعذّر حذف التعليق');
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_file.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : null,
            ),
            onPressed: _toggleFavorite,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'share') _share();
              if (v == 'report') _report();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'share', child: Text('مشاركة')),
              PopupMenuItem(value: 'report', child: Text('إبلاغ')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF60A5FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: FileTypeIcon(filename: _file.filename, color: Colors.white, size: 72),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _file.title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _file.category?.name ?? 'غير مصنّف',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
          ),
          if (_file.description != null && _file.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_file.description!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          _statsCard(),
          const SizedBox(height: 16),
          _ratingSection(theme),
          const SizedBox(height: 16),
          _actionButtons(),
          const SizedBox(height: 24),
          Text(
            'التعليقات',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _commentInput(),
          const SizedBox(height: 8),
          if (_loadingComments)
            const Center(
              child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
            )
          else if (_commentList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('لا توجد تعليقات بعد', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ..._commentList.map((c) => _commentTile(c)),
        ],
      ),
    );
  }

  Widget _statsCard() {
    final stats = _file.stats;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.visibility, stats.viewsCount, 'قراءة'),
          _statItem(Icons.download, stats.downloadsCount, 'تحميل'),
          _statItem(Icons.favorite, stats.favoritesCount, 'مفضلة'),
          _statItem(Icons.star, stats.ratingsCount, 'تقييم'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, int value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _ratingSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Text(
                _file.stats.avgRating.toStringAsFixed(1),
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RatingBar.builder(
            initialRating: (_file.myRating ?? 0).toDouble(),
            minRating: 1,
            maxRating: 5,
            allowHalfRating: false,
            itemCount: 5,
            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (v) => _rate(v.round()),
          ),
          const SizedBox(height: 4),
          Text(
            _file.myRating != null ? 'تقييمك: ${_file.myRating}' : 'قيّم هذا الملف',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Column(
      children: [
        if (_isDownloading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LinearProgressIndicator(),
          ),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _isDownloading ? null : _read,
                icon: const Icon(Icons.menu_book),
                label: const Text('قراءة'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isDownloading ? null : _downloadFile,
                icon: const Icon(Icons.download),
                label: const Text('تحميل'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleOffline,
                icon: Icon(_isOffline ? Icons.offline_pin : Icons.offline_pin_outlined),
                label: Text(_isOffline ? 'متاح' : 'بلا إنترنت'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _commentInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'اكتب تعليقاً...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: _isSubmittingComment
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          onPressed: _isSubmittingComment ? null : _addComment,
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _commentTile(Comment c) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    c.user?.name.isNotEmpty == true ? c.user!.name[0] : '؟',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.user?.name ?? 'مستخدم',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (c.mine)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _editComment(c);
                      if (v == 'delete') _deleteComment(c);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(c.body),
          ],
        ),
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('الإبلاغ عن هذا الملف'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'سبب الإبلاغ (اختياري)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('إرسال'),
        ),
      ],
    );
  }
}
