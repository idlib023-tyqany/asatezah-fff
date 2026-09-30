import 'package:flutter/material.dart';

import '../../services/admin_service.dart';

class AdminReports extends StatefulWidget {
  const AdminReports({super.key});

  @override
  State<AdminReports> createState() => _AdminReportsState();
}

class _AdminReportsState extends State<AdminReports> {
  final _admin = AdminService();
  List<dynamic> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// جلب البلاغات من السيرفر
  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final list = await _admin.fetchReports();
      if (!mounted) return;
      setState(() {
        _reports = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// إظهار رسائل التنبيه بشكل منظم
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// تنفيذ الإجراء (حل أو رفض البلاغ) وتحديث القائمة محلياً
  Future<void> _handleAction(
    int reportId,
    Future<void> Function() action,
    String successMsg,
  ) async {
    try {
      await action();
      if (!mounted) return;

      // تحديث محلي سريع بدون الحاجة لإعادة جلب القائمة بالكامل من السيرفر
      setState(() {
        _reports.removeWhere((r) => r['id'] == reportId);
      });

      _showSnackBar(successMsg);
    } catch (_) {
      _showSnackBar('تعذرت معالجة البلاغ، حاول لاحقاً', isError: true);
    }
  }

  /// نافذة تفاصيل البلاغ
  void _showReportDetails(Map<String, dynamic> r) {
    final file = r['file'];
    final user = r['user'];
    final reason = r['reason']?.toString() ?? 'بدون سبب مذكور';
    final reportId = r['id'] as int;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                icon: Icons.insert_drive_file_outlined,
                title: 'الملف المُبلغ عنه',
                value: file?['title'] ?? 'ملف مجهول',
                isBold: true,
              ),
              const SizedBox(height: 12),
              _detailRow(
                icon: Icons.person_outline,
                title: 'المُبلغ',
                value: '${user?['name'] ?? 'مستخدم مجهول'} (${user?['email'] ?? 'بدون بريد'})',
              ),
              const SizedBox(height: 16),
              const Text(
                'سبب البلاغ:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withAlpha(50)),
                ),
                child: Text(reason, style: const TextStyle(fontSize: 13, height: 1.4)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction(reportId, () => _admin.dismissReport(reportId), 'تم رفض البلاغ');
            },
            child: const Text('رفض البلاغ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction(reportId, () => _admin.resolveReport(reportId), 'تم حل البلاغ بنجاح');
            },
            child: const Text('حل البلاغ'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة البلاغات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _reports.isEmpty
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
                      itemCount: _reports.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final r = _reports[index];
                        final file = r['file'];
                        final user = r['user'];
                        final reason = r['reason']?.toString() ?? '';
                        final reportId = r['id'] as int;

                        return ListTile(
                          onTap: () => _showReportDetails(r),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          ),
                          title: Text(
                            file?['title'] ?? 'ملف مجهول',
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                tooltip: 'حل البلاغ',
                                onPressed: () => _handleAction(
                                  reportId,
                                  () => _admin.resolveReport(reportId),
                                  'تم حل البلاغ',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
                                tooltip: 'رفض البلاغ',
                                onPressed: () => _handleAction(
                                  reportId,
                                  () => _admin.dismissReport(reportId),
                                  'تم رفض البلاغ',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
