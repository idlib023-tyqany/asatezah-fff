import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import 'admin_settings.dart';

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
        _errorMessage = 'حدث خطأ أثناء تحميل الإحصائيات';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإدارة'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'تحديث البيانات'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // عرض الإحصائيات في شبكة بعمودين
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _statGridCard(
                        'إجمالي الملفات',
                        _stats?['total_files'],
                        Icons.folder,
                        const Color(0xFF1E40AF),
                      ),
                      _statGridCard(
                        'منشورة',
                        _stats?['published_files'],
                        Icons.published_with_changes,
                        const Color(0xFF16A34A),
                      ),
                      _statGridCard(
                        'قيد المراجعة',
                        _stats?['pending_files'],
                        Icons.pending_actions,
                        const Color(0xFFF59E0B),
                      ),
                      _statGridCard(
                        'في المهملات',
                        _stats?['trashed_files'],
                        Icons.delete_outline,
                        const Color(0xFFDC2626),
                      ),
                      _statGridCard(
                        'التحميلات',
                        _stats?['total_downloads'],
                        Icons.download,
                        const Color(0xFF7C3AED),
                      ),
                      _statGridCard(
                        'المشاهدات',
                        _stats?['total_views'],
                        Icons.visibility,
                        const Color(0xFF0D9488),
                      ),
                      _statGridCard(
                        'المستخدمون',
                        _stats?['total_users'],
                        Icons.people,
                        const Color(0xFF2563EB),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // بطاقة سريعة للانتقال للإعدادات والشعار
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.branding_watermark_outlined,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      title: const Text(
                        'هوية التطبيق والشعار',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('تعديل اسم التطبيق أو رفع شعار جديد'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () =>
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const AdminSettings())),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // بطاقة الإحصائيات المحسّنة للشبكة
  Widget _statGridCard(String label, dynamic value, IconData icon, Color color) {
    final String displayValue = (value ?? 0).toString();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withAlpha(35),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  displayValue,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
