import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_config.dart';
import './app_info_model.dart';
import './app_info_service.dart';
import './app_info_view.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  final _service = AppInfoService();
  AppInfo _info = const AppInfo(name: 'أساتذة', version: '', links: {});
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
      final info = await _service.fetchInfo();
      if (!mounted) return;
      setState(() {
        _info = info;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'تعذر تحميل معلومات التطبيق. تحقق من اتصالك وحاول مجدداً.';
      });
    }
  }

  Future<void> _share() async {
    final website = _info.links['website'] ?? '';
    final shareText = [
      _info.name,
      if (_info.version.isNotEmpty) 'الإصدار ${_info.version}',
      'المكتبة الرقمية للأساتذة',
      if (website.isNotEmpty) website,
    ].join('\n');

    await SharePlus.instance.share(ShareParams(text: shareText));
  }

  Future<void> _openUrl(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) return;

    final uri = Uri.tryParse(urlString.trim());
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
          _info.version.isNotEmpty
              ? 'تطبيقك هو آخر إصدار متاح (${_info.version})'
              : 'جاري التحقق من الإصدار الحالي...',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoPath = _info.logoPath;
    final String? logoUrl =
        logoPath == null || logoPath.trim().isEmpty ? null : '${ApiConfig.storageUrl}/$logoPath';

    return AppInfoView(
      info: _info,
      logoUrl: logoUrl,
      isLoading: _loading,
      errorMessage: _errorMessage,
      onRefresh: _load,
      onShare: _share,
      onCheckForUpdates: _checkForUpdates,
      onOpenUrl: _openUrl,
    );
  }
}
