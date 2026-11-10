import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:asatezah/core/network/api_config.dart';
import 'package:asatezah/features/app_info/app_info_service.dart';

import './update_check_view.dart';
class UpdateCheckScreen extends StatefulWidget {
  const UpdateCheckScreen({super.key});

  @override
  State<UpdateCheckScreen> createState() => _UpdateCheckScreenState();
}

class _UpdateCheckScreenState extends State<UpdateCheckScreen> {
  final _appService = AppInfoService();

  bool _loading = true;
  String? _errorMessage;
  String _currentVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _initAndCheck();
  }

  /// الفحص الابتدائي والإرسال للسيرفر
  Future<void> _initAndCheck() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // قراءة رقم الإصدار الحالي تلقائياً من التطبيق
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      // جلب معلومات التطبيق والتحديثات من السيرفر
      final info = await _appService.fetchInfo();
      final latestVersion = info.version;
      final isRequired = info.isUpdateRequired;
      final updateUrl = info.links['website']?.toString() ?? ApiConfig.baseUrl;

      if (_shouldUpdate(_currentVersion, latestVersion)) {
        if (!mounted) return;
        _showUpdateDialog(
          latestVersion: latestVersion,
          isRequired: isRequired,
          updateUrl: updateUrl,
        );
      } else {
        _navigateToHome();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'تعذّر الاتصال بالسيرفر للتحقق من التحديثات';
      });
    }
  }

  /// دالة آمنة لمقارنة أرقام الإصدارات (تتعامل مع SemVer مثل: 1.2.0, 1.10.0+5, إلخ)
  bool _shouldUpdate(String current, String latest) {
    try {
      final currentParts = _parseVersion(current);
      final latestParts = _parseVersion(latest);

      final maxLength = currentParts.length > latestParts.length
          ? currentParts.length
          : latestParts.length;

      for (int i = 0; i < maxLength; i++) {
        final currentNum = i < currentParts.length ? currentParts[i] : 0;
        final latestNum = i < latestParts.length ? latestParts[i] : 0;

        if (latestNum > currentNum) return true;
        if (latestNum < currentNum) return false;
      }
    } catch (_) {
      // مقارنة احتياطية في حالة وجود نص غير متوقع
      return current.trim() != latest.trim();
    }
    return false;
  }

  /// استخراج الأجزاء الرقمية من نص الإصدار واستبعاد إضافات مثل (+ build number)
  List<int> _parseVersion(String version) {
    final cleanVersion = version.split('+').first.split('-').first;
    return cleanVersion.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  /// فتح رابط التحديث في المتصفح الخارجي أو المتجر
  Future<void> _launchUpdateUrl(String urlString) async {
    final Uri? uri = Uri.tryParse(urlString.trim());
    if (uri == null) {
      _showSnackBar('رابط التحديث غير صالح');
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _showSnackBar('تعذّر فتح رابط التحديث');
      }
    } catch (_) {
      _showSnackBar('حدث خطأ أثناء فتح الرابط');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  /// نافذة حوار التحديث الإجباري / الاختياري
  void _showUpdateDialog({
    required String latestVersion,
    required bool isRequired,
    required String updateUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isRequired,
      useRootNavigator: false,
      builder: (BuildContext ctx) {
        return PopScope(
          canPop: !isRequired,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  isRequired ? Icons.system_update_sharp : Icons.system_update_alt_rounded,
                  color: isRequired ? Colors.red : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                const Text('تحديث جديد متاح'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRequired
                      ? 'يتوفر تحديث إجباري يضم تحسينات مهمة وأمان إضافي (الإصدار $latestVersion). يرجى التحديث لمتابعة الاستخدام.'
                      : 'يتوفر إصدار جديد من التطبيق ($latestVersion). هل ترغب بالتحديث الآن؟',
                  style: const TextStyle(height: 1.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'إصدارك الحالي: $_currentVersion',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              if (!isRequired)
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _navigateToHome();
                  },
                  child: const Text('التخطي الآن'),
                )
              else
                TextButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text('إغلاق التطبيق', style: TextStyle(color: Colors.grey)),
                ),
              FilledButton.icon(
                onPressed: () {
                  _launchUpdateUrl(updateUrl);
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('تحديث الآن'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return UpdateCheckView(
      isLoading: _loading,
      errorMessage: _errorMessage,
      onContinue: _navigateToHome,
      onRetry: _initAndCheck,
    );
  }
}
