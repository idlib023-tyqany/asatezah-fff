import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../services/app_service.dart';
import '../../widgets/app_logo.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  final _service = AppService();
  String _name = 'أساتذة';
  String _version = '';
  String? _logoPath;
  Map<String, String?> _links = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final info = await _service.fetchInfo();
      if (!mounted) return;
      setState(() {
        _name = info.name;
        _version = info.version;
        _logoPath = info.logoPath;
        _links = info.links;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? get _logoUrl {
    if (_logoPath == null || _logoPath!.trim().isEmpty) return null;
    return '${ApiConfig.storageUrl}/${_logoPath!}';
  }

  Future<void> _share() async {
    final website = _links['website'] ?? '';
    final text = [
      _name,
      if (_version.isNotEmpty) 'الإصدار $_version',
      'المكتبة الرقمية للأساتذة',
      if (website.isNotEmpty) website,
    ].join('\n');

    // ✅ تم التعديل للاستدعاء المتوافق مع مكتبة share_plus الحديثة
    await Share.share(text);
  }

  Future<void> _openUrl(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) return;

    final Uri? uri = Uri.tryParse(urlString.trim());
    if (uri == null) return;

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذر فتح الرابط: $urlString')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء محاولة فتح الرابط')));
      }
    }
  }

  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _version.isNotEmpty
              ? 'تطبيقك هو آخر إصدار متاح ($_version)'
              : 'جاري التحقق من الإصدار الحالي...',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoUrl = _logoUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حول التطبيق'),
        actions: [
          IconButton(onPressed: _share, icon: const Icon(Icons.share_outlined), tooltip: 'مشاركة'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  const SizedBox(height: 12),
                  // شعار التطبيق
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
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(Icons.school_rounded, size: 52),
                            )
                          : const AppLogo(size: 100),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // اسم التطبيق والإصدار
                  Text(
                    _name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (_version.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'الإصدار $_version',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // شارة حالة الإصدار (محاذاة في المنتصف)
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
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // أزرار التحديث والمشاركة
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _checkForUpdates,
                          icon: const Icon(Icons.system_update_outlined),
                          label: const Text('تحديث'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _share,
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('مشاركة'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // قائمة الروابط والقنوات
                  if (_links.values.any((v) => v != null && v.trim().isNotEmpty)) ...[
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
                ],
              ),
      ),
    );
  }

  List<Widget> _buildLinks(ThemeData theme) {
    final entries = <(IconData, String, String?)>[
      (Icons.telegram, 'تيليغرام', _links['telegram']),
      (Icons.play_circle_fill_rounded, 'يوتيوب', _links['youtube']),
      (Icons.facebook, 'فيسبوك', _links['facebook']),
      (Icons.camera_alt_rounded, 'إنستغرام', _links['instagram']),
      (Icons.chat_bubble_rounded, 'واتساب', _links['whatsapp']),
      (Icons.language_rounded, 'الموقع وصفحة التحميل', _links['website']),
    ];

    final validEntries = entries.where((e) => e.$3 != null && e.$3!.trim().isNotEmpty).toList();

    return validEntries.asMap().entries.map((entry) {
      final idx = entry.key;
      final e = entry.value;
      final isLast = idx == validEntries.length - 1;

      return Column(
        children: [
          ListTile(
            leading: Icon(e.$1, color: theme.colorScheme.primary),
            title: Text(e.$2, style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: Icon(Icons.open_in_new_rounded, size: 18, color: theme.colorScheme.outline),
            onTap: () => _openUrl(e.$3),
          ),
          if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      );
    }).toList();
  }
}
