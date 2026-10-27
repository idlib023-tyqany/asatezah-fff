import 'package:flutter/material.dart';

enum AdminFileReviewAction {
  approve,
  reject,
  reopen,
  move,
  trash,
  restore,
  forceDelete,
}

class AdminFileReviewView extends StatelessWidget {
  const AdminFileReviewView({
    required this.title,
    required this.isTrash,
    required this.files,
    required this.isLoading,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onEmptyTrash,
    required this.onAction,
    super.key,
  });

  final String title;
  final bool isTrash;
  final List<Map<String, dynamic>> files;
  final bool isLoading;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function() onRefresh;
  final VoidCallback onEmptyTrash;
  final void Function(Map<String, dynamic> file, AdminFileReviewAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (isTrash && files.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever_outlined),
              tooltip: 'تفريغ سلة المهملات',
              onPressed: onEmptyTrash,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'بحث في الملفات...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: onClearSearch,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: onRefresh,
                    child: files.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Text(
                                  'لا توجد ملفات في القائمة',
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            itemCount: files.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) => _fileTile(context, files[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _fileTile(BuildContext context, Map<String, dynamic> file) {
    final uploader = file['uploader'] as Map<String, dynamic>?;
    final status = file['status']?.toString() ?? '';
    final category = file['category'] as Map<String, dynamic>?;
    final material = file['material'] as Map<String, dynamic>?;
    final details = [
      category?['name']?.toString() ?? '',
      material?['name']?.toString() ?? '',
      uploader != null ? 'رفع: ${uploader['name'] ?? ''}' : '',
    ].where((value) => value.isNotEmpty).join(' • ');

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withAlpha(20),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.insert_drive_file_outlined, color: Theme.of(context).primaryColor),
      ),
      title: Text(
        file['title']?.toString() ?? 'بدون عنوان',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(details, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            _statusBadge(status),
          ],
        ),
      ),
      trailing: _actions(file, status),
    );
  }

  Widget _statusBadge(String status) {
    final Color color;
    final String label;
    if (isTrash) {
      color = Colors.red;
      label = 'في المهملات';
    } else {
      switch (status) {
        case 'published':
          color = Colors.green;
          label = 'منشور';
        case 'pending':
          color = Colors.orange;
          label = 'قيد المراجعة';
        case 'rejected':
          color = Colors.red;
          label = 'مرفوض';
        default:
          color = Colors.grey;
          label = status;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(100), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _actions(Map<String, dynamic> file, String status) {
    final items = isTrash
        ? <PopupMenuEntry<AdminFileReviewAction>>[
            const PopupMenuItem(
              value: AdminFileReviewAction.restore,
              child: ListTile(
                leading: Icon(Icons.restore, color: Colors.green),
                title: Text('استعادة'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: AdminFileReviewAction.forceDelete,
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text('حذف نهائي'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ]
        : <PopupMenuEntry<AdminFileReviewAction>>[
            if (status == 'pending') ...[
              const PopupMenuItem(
                value: AdminFileReviewAction.approve,
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('موافقة ونشر'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: AdminFileReviewAction.reject,
                child: ListTile(
                  leading: Icon(Icons.cancel, color: Colors.red),
                  title: Text('رفض'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            if (status == 'rejected')
              const PopupMenuItem(
                value: AdminFileReviewAction.reopen,
                child: ListTile(
                  leading: Icon(Icons.replay, color: Colors.orange),
                  title: Text('إعادة فتح للمراجعة'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            if (status == 'published')
              const PopupMenuItem(
                value: AdminFileReviewAction.move,
                child: ListTile(
                  leading: Icon(Icons.drive_file_move_outlined, color: Colors.blue),
                  title: Text('نقل إلى تصنيف/مادة'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuItem(
              value: AdminFileReviewAction.trash,
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('نقل لسلة المهملات'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ];
    return PopupMenuButton<AdminFileReviewAction>(
      onSelected: (action) => onAction(file, action),
      itemBuilder: (_) => items,
    );
  }
}
