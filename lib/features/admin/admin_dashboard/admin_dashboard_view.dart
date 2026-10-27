import 'package:flutter/material.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({
    required this.stats,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onOpenSettings,
    super.key,
  });

  final Map<String, dynamic>? stats;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'لوحة الإدارة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: onRefresh,
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.25,
                    children: [
                      _buildStatCard('إجمالي الملفات', stats?['total_files'], Icons.folder_rounded,
                          const Color(0xFF2563EB)),
                      _buildStatCard('منشورة', stats?['published_files'], Icons.check_circle_rounded,
                          const Color(0xFF16A34A)),
                      _buildStatCard('قيد المراجعة', stats?['pending_files'], Icons.hourglass_top_rounded,
                          const Color(0xFFD97706)),
                      _buildStatCard('في المهملات', stats?['trashed_files'], Icons.delete_outline_rounded,
                          const Color(0xFFDC2626)),
                      _buildStatCard('التحميلات', stats?['total_downloads'], Icons.file_download_outlined,
                          const Color(0xFF9333EA)),
                      _buildStatCard('المشاهدات', stats?['total_views'], Icons.remove_red_eye_outlined,
                          const Color(0xFF0D9488)),
                      _buildStatCard('المستخدمون', stats?['total_users'], Icons.people_alt_rounded,
                          const Color(0xFF0284C7)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'إجراءات سريعة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(context),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_rounded, size: 32, color: theme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نظرة عامة على التطبيق',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: theme.primaryColor),
                ),
                const SizedBox(height: 2),
                Text(
                  'تابع إحصائيات النشاط والملفات والمستخدمين مباشرة',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              FittedBox(
                child: Text(
                  (value ?? 0).toString(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey[700],
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onOpenSettings,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.branding_watermark_rounded,
              color: Theme.of(context).primaryColor),
        ),
        title: const Text('هوية التطبيق والشعار',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('تعديل اسم التطبيق، إعدادات النظام، أو رفع شعار جديد',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(errorMessage!, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
