import 'package:flutter/material.dart';

class AdminReportsView extends StatelessWidget {
  const AdminReportsView({
    required this.reports,
    required this.isLoading,
    required this.processingReportIds,
    required this.onRefresh,
    required this.onResolve,
    required this.onDismiss,
    super.key,
  });

  final List<Map<String, dynamic>> reports;
  final bool isLoading;
  final Set<int> processingReportIds;
  final Future<void> Function() onRefresh;
  final ValueChanged<Map<String, dynamic>> onResolve;
  final ValueChanged<Map<String, dynamic>> onDismiss;

  int _reportId(Map<String, dynamic> report) {
    final id = report['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة البلاغات')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: onRefresh,
              child: reports.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                              SizedBox(height: 12),
                              Text(
                                'لا توجد بلاغات مفتوحة حالياً',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: reports.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) => _reportTile(context, reports[index]),
                    ),
            ),
    );
  }

  Widget _reportTile(BuildContext context, Map<String, dynamic> report) {
    final file = report['file'] as Map<String, dynamic>?;
    final user = report['user'] as Map<String, dynamic>?;
    final reason = report['reason']?.toString() ?? '';
    final reportId = _reportId(report);
    final isProcessing = processingReportIds.contains(reportId);
    return ListTile(
      onTap: () => _showDetails(context, report, isProcessing),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.orange.withAlpha(25), shape: BoxShape.circle),
        child: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
      ),
      title: Text(
        file?['title']?.toString() ?? 'ملف مجهول',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          'بواسطة: ${user?['name'] ?? '?'}',
          reason.isNotEmpty ? reason : 'بدون سبب',
        ].join(' • '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: isProcessing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  tooltip: 'حل البلاغ',
                  onPressed: () => onResolve(report),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
                  tooltip: 'رفض البلاغ',
                  onPressed: () => onDismiss(report),
                ),
              ],
            ),
    );
  }

  void _showDetails(
    BuildContext context,
    Map<String, dynamic> report,
    bool isProcessing,
  ) {
    final file = report['file'] as Map<String, dynamic>?;
    final user = report['user'] as Map<String, dynamic>?;
    final reason = report['reason']?.toString() ?? 'بدون سبب مذكور';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('تفاصيل البلاغ'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(
                context,
                icon: Icons.insert_drive_file_outlined,
                title: 'الملف المُبلغ عنه',
                value: file?['title']?.toString() ?? 'ملف مجهول',
                isBold: true,
              ),
              const SizedBox(height: 12),
              _detailRow(
                context,
                icon: Icons.person_outline,
                title: 'المُبلغ',
                value: '${user?['name'] ?? 'مستخدم مجهول'} (${user?['email'] ?? 'بدون بريد'})',
              ),
              const SizedBox(height: 16),
              const Text('سبب البلاغ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(reason, style: const TextStyle(fontSize: 13, height: 1.4)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isProcessing ? null : () => Navigator.pop(dialogContext),
            child: const Text('إغلاق'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: isProcessing
                ? null
                : () {
                    Navigator.pop(dialogContext);
                    onDismiss(report);
                  },
            child: const Text('رفض البلاغ'),
          ),
          FilledButton(
            onPressed: isProcessing
                ? null
                : () {
                    Navigator.pop(dialogContext);
                    onResolve(report);
                  },
            child: const Text('حل البلاغ'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.outline),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
