import 'package:flutter/material.dart';

import 'package:asatezah/features/admin/admin_dashboard/admin_dashboard_service.dart';
import './admin_reports_view.dart';

class AdminReports extends StatefulWidget {
  const AdminReports({super.key});

  @override
  State<AdminReports> createState() => _AdminReportsState();
}

class _AdminReportsState extends State<AdminReports> {
  final _admin = AdminService();
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  // لتتبع البلاغات الجاري معالجتها ومنع تكرار الضغط
  final Set<int> _processingReportIds = {};

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
        _reports = list.whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      _showSnackBar('تعذر تحميل البلاغات', isError: true);
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
    if (_processingReportIds.contains(reportId)) return;

    setState(() => _processingReportIds.add(reportId));

    try {
      await action();
      if (!mounted) return;

      // تحديث محلي سريع بدون الحاجة لإعادة جلب القائمة بالكامل من السيرفر
      setState(() {
        _reports.removeWhere((r) => _parseReportId(r['id']) == reportId);
      });

      _showSnackBar(successMsg);
    } catch (_) {
      _showSnackBar('تعذرت معالجة البلاغ، حاول لاحقاً', isError: true);
    } finally {
      if (mounted) {
        setState(() => _processingReportIds.remove(reportId));
      }
    }
  }

  /// استخراج معرف البلاغ بأمان
  int _parseReportId(dynamic id) {
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    return 0;
  }

  /// نافذة تفاصيل البلاغ
  @override
  Widget build(BuildContext context) {
    return AdminReportsView(
      reports: _reports,
      isLoading: _loading,
      processingReportIds: _processingReportIds,
      onRefresh: _load,
      onResolve: (report) {
        final id = _parseReportId(report['id']);
        _handleAction(id, () => _admin.resolveReport(id), 'تم حل البلاغ');
      },
      onDismiss: (report) {
        final id = _parseReportId(report['id']);
        _handleAction(id, () => _admin.dismissReport(id), 'تم رفض البلاغ');
      },
    );
  }
}
