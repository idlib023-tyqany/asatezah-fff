import 'package:flutter/material.dart';

import 'package:asatezah/core/widgets/app_logo.dart';
import './app_info_model.dart';

class AppInfoView extends StatelessWidget {
  const AppInfoView({
    required this.info,
    this.logoUrl,
    required this.isLoading,
    required this.onRefresh,
    required this.onShare,
    required this.onCheckForUpdates,
    required this.onOpenUrl,
    this.errorMessage,
    super.key,
  });

  final AppInfo info;
  final String? logoUrl;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final VoidCallback onShare;
  final VoidCallback onCheckForUpdates;
  final ValueChanged<String?> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حول التطبيق'),
        actions: [
          IconButton(onPressed: onShare, icon: const Icon(Icons.share_outlined), tooltip: 'مشاركة'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: isLoading
            ? ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 280, child: Center(child: CircularProgressIndicator())),
                ],
              )
            : errorMessage != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  Center(child: Text(errorMessage!, textAlign: TextAlign.center)),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(onPressed: onRefresh, child: const Text('إعادة المحاولة')),
                  ),
                ],
              )
            : _buildContent(context, theme),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 100,
            height: 100,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: logoUrl != null
                ? Image.network(
                    logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.school_rounded, size: 52),
                  )
                : const AppLogo(size: 100),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          info.name,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (info.version.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'الإصدار ${info.version}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text(
                  'الإصدار الحالي مثبت',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCheckForUpdates,
                icon: const Icon(Icons.system_update_outlined),
                label: const Text('تحديث'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded),
                label: const Text('مشاركة'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ),
        if (info.links.values.any((value) => value != null && value.trim().isNotEmpty)) ...[
          const SizedBox(height: 32),
          Text(
            'قنوات التطبيق وروابطه',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(children: _buildLinks(theme)),
          ),
        ],
        const SizedBox(height: 40),
        Text(
          'المكتبة الرقمية للأساتذة',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _buildLinks(ThemeData theme) {
    final entries = <(IconData, String, String?)>[
      (Icons.telegram, 'تيليغرام', info.links['telegram']),
      (Icons.play_circle_fill_rounded, 'يوتيوب', info.links['youtube']),
      (Icons.facebook, 'فيسبوك', info.links['facebook']),
      (Icons.camera_alt_rounded, 'إنستغرام', info.links['instagram']),
      (Icons.chat_bubble_rounded, 'واتساب', info.links['whatsapp']),
      (Icons.language_rounded, 'الموقع وصفحة التحميل', info.links['website']),
    ];

    final validEntries = entries.where((entry) => entry.$3?.trim().isNotEmpty ?? false).toList();

    return validEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final link = entry.value;
      final isLast = index == validEntries.length - 1;

      return Column(
        children: [
          ListTile(
            leading: Icon(link.$1, color: theme.colorScheme.primary),
            title: Text(link.$2, style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: Icon(Icons.open_in_new_rounded, size: 18, color: theme.colorScheme.outline),
            onTap: () => onOpenUrl(link.$3),
          ),
          if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      );
    }).toList();
  }
}
