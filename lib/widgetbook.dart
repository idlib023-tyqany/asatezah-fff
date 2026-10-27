// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:asatezah/features/app_info/app_info_model.dart';
import 'package:asatezah/features/app_info/app_info_view.dart';

void main() {
  runApp(const HotReloadWidgetbook());
}

class HotReloadWidgetbook extends StatelessWidget {
  const HotReloadWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      appBuilder: (context, child) => MaterialApp(debugShowCheckedModeBanner: false, home: child),
      directories: [
        WidgetbookFolder(
          name: 'شاشات الإعدادات',
          children: [
            WidgetbookComponent(
              name: 'حول التطبيق',
              useCases: [
                WidgetbookUseCase(
                  name: 'المعاينة',
                  builder: (context) => AppInfoView(
                    info: const AppInfo(
                      name: 'أساتذة',
                      version: '1.0.0',
                      links: {
                        'telegram': 'https://t.me/asatezah',
                        'website': 'https://asatezah.com',
                      },
                    ),
                    isLoading: false,
                    onRefresh: () async {},
                    onShare: () {},
                    onCheckForUpdates: () {},
                    onOpenUrl: (_) {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
