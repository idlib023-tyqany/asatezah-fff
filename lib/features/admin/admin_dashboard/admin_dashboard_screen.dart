import 'package:flutter/material.dart';

import 'package:asatezah/features/admin/admin_dashboard/admin_dashboard_service.dart';
import '../admin_settings/admin_settings_screen.dart';
import './admin_dashboard_view.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _admin = AdminService();
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _admin.statistics();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'حدث خطأ أثناء تحميل الإحصائيات، يرجى التحقق من الاتصال.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminDashboardView(
      stats: _stats,
      isLoading: _loading,
      errorMessage: _errorMessage,
      onRefresh: _load,
      onOpenSettings: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminSettings()),
        );
      },
    );
  }
}
