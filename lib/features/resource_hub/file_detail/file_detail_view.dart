import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'package:asatezah/core/widgets/file_type_icon.dart';
import 'package:asatezah/features/resource_hub/resource_hub/resource_hub_model.dart';

class FileDetailView extends StatelessWidget {
  final FileItem file;
  final List<Comment> comments;
  final bool isFavorite;
  final bool isOffline;
  final bool isDownloading;
  final bool isSubmittingComment;
  final bool isLoadingComments;
  final TextEditingController commentController;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;
  final Future<void> Function(String? reason) onReport;
  final ValueChanged<int> onRate;
  final VoidCallback onRead;
  final VoidCallback onDownload;
  final VoidCallback onToggleOffline;
  final VoidCallback onAddComment;
  final Future<void> Function(Comment comment, String body) onEditComment;
  final Future<void> Function(Comment comment) onDeleteComment;

  const FileDetailView({
    super.key,
    required this.file,
    required this.comments,
    required this.isFavorite,
    required this.isOffline,
    required this.isDownloading,
    required this.isSubmittingComment,
    required this.isLoadingComments,
    required this.commentController,
    required this.onToggleFavorite,
    required this.onShare,
    required this.onReport,
    required this.onRate,
    required this.onRead,
    required this.onDownload,
    required this.onToggleOffline,
    required this.onAddComment,
    required this.onEditComment,
    required this.onDeleteComment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(file.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : null,
            ),
            onPressed: onToggleFavorite,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'share') onShare();
              if (value == 'report') _report(context);
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
              child: FileTypeIcon(filename: file.filename, color: Colors.white, size: 72),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            file.title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            file.category?.name ?? 'غير مصنّف',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
          ),
          if (file.description != null && file.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(file.description!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          _statsCard(context),
          const SizedBox(height: 16),
          _ratingSection(context, theme),
          const SizedBox(height: 16),
          _actionButtons(),
          const SizedBox(height: 24),
          Text(
            'التعليقات',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _commentInput(context),
          const SizedBox(height: 8),
          if (isLoadingComments)
            const Center(
              child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
            )
          else if (comments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('لا توجد تعليقات بعد', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...comments.map((comment) => _commentTile(context, comment)),
        ],
      ),
    );
  }

  Widget _statsCard(BuildContext context) {
    final stats = file.stats;
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
          _statItem(context, Icons.visibility, stats.viewsCount, 'قراءة'),
          _statItem(context, Icons.download, stats.downloadsCount, 'تحميل'),
          _statItem(context, Icons.favorite, stats.favoritesCount, 'مفضلة'),
          _statItem(context, Icons.star, stats.ratingsCount, 'تقييم'),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, IconData icon, int value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _ratingSection(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
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
                file.stats.avgRating.toStringAsFixed(1),
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RatingBar.builder(
            initialRating: (file.myRating ?? 0).toDouble(),
            minRating: 1,
            maxRating: 5,
            allowHalfRating: false,
            itemCount: 5,
            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (value) => onRate(value.round()),
          ),
          const SizedBox(height: 4),
          Text(
            file.myRating != null ? 'تقييمك: ${file.myRating}' : 'قيّم هذا الملف',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Column(
      children: [
        if (isDownloading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isDownloading ? null : onRead,
                icon: const Icon(Icons.menu_book),
                label: const Text('قراءة'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isDownloading ? null : onDownload,
                icon: const Icon(Icons.download),
                label: const Text('تحميل'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onToggleOffline,
                icon: Icon(isOffline ? Icons.offline_pin : Icons.offline_pin_outlined),
                label: Text(isOffline ? 'متاح' : 'بلا إنترنت'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _commentInput(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: commentController,
            decoration: const InputDecoration(
              hintText: 'اكتب تعليقاً...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: isSubmittingComment
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          onPressed: isSubmittingComment ? null : onAddComment,
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _commentTile(BuildContext context, Comment comment) {
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
                    comment.user?.name.isNotEmpty == true ? comment.user!.name[0] : '؟',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    comment.user?.name ?? 'مستخدم',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (comment.mine)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _editComment(context, comment);
                      if (value == 'delete') _deleteComment(context, comment);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(comment.body),
          ],
        ),
      ),
    );
  }

  Future<void> _report(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _ReportDialog(),
    );
    if (reason != null) await onReport(reason);
  }

  Future<void> _editComment(BuildContext context, Comment comment) async {
    final controller = TextEditingController(text: comment.body);
    final body = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل التعليق'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (body != null && body.trim().isNotEmpty) {
      await onEditComment(comment, body);
    }
  }

  Future<void> _deleteComment(BuildContext context, Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف التعليق'),
        content: const Text('هل أنت تأكد من رغبتك في حذف هذا التعليق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) await onDeleteComment(comment);
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
