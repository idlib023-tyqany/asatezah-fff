import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login/login_screen.dart';
import 'features/auth/otp/otp_verification_screen.dart';
import 'features/auth/profile_settings_screen.dart';
import 'features/auth/register/register_screen.dart';
import 'features/library/home/home_screen.dart';

void main() {
  runApp(const ScreensPreviewApp());
}

class ScreensPreviewApp extends StatefulWidget {
  const ScreensPreviewApp({super.key});

  @override
  State<ScreensPreviewApp> createState() => _ScreensPreviewAppState();
}

class _ScreensPreviewAppState extends State<ScreensPreviewApp> {
  int _selectedIndex = 0;
  ThemeMode _themeMode = ThemeMode.light;

  static const _screenNames = [
    'تسجيل الدخول',
    'إنشاء حساب',
    'رمز التحقق',
    'معلومات الحساب',
    'المكتبة الرئيسية',
  ];

  Widget _selectedScreen() {
    return switch (_selectedIndex) {
      0 => const LoginScreen(previewMode: true),
      1 => const RegisterScreen(previewMode: true),
      2 => const OtpVerificationScreen(
        previewMode: true,
        challenge: {
          'verification_id': 'dummy_id',
          'verificationId': 'dummy_id',
          'email': 'test@example.com',
          'phone_number': '+963912345678',
          'phoneNumber': '+963912345678',
          'channels': ['email', 'phone'],
          'destinations': {
            'email': 'test@example.com',
            'phone': '+963912345678',
          },
        },
      ),
      3 => const ProfileSettingsScreen(previewMode: true),
      _ => const HomeScreen(previewMode: true),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return MaterialApp(
      title: 'معاينة شاشات أساتذة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        appBar: AppBar(
          title: isWide
              ? const Text('معاينة شاشات أساتذة')
              : DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedIndex,
                    items: [
                      for (var index = 0; index < _screenNames.length; index++)
                        DropdownMenuItem(
                          value: index,
                          child: Text(_screenNames[index]),
                        ),
                    ],
                    onChanged: (index) {
                      if (index != null) {
                        setState(() => _selectedIndex = index);
                      }
                    },
                  ),
                ),
          actions: [
            IconButton(
              tooltip: _themeMode == ThemeMode.dark
                  ? 'التبديل إلى الوضع المضيء'
                  : 'التبديل إلى الوضع المظلم',
              icon: Icon(
                _themeMode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              onPressed: () {
                setState(() {
                  _themeMode = _themeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                });
              },
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (isWide) {
              return Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    labelType: NavigationRailLabelType.all,
                    onDestinationSelected: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.login_outlined),
                        label: Text('الدخول'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_add_outlined),
                        label: Text('التسجيل'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.verified_user_outlined),
                        label: Text('التحقق'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.manage_accounts_outlined),
                        label: Text('الحساب'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.library_books_outlined),
                        label: Text('المكتبة'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: Center(child: _PhoneFrame(child: _selectedScreen())),
                  ),
                ],
              );
            }

            return Center(child: _PhoneFrame(child: _selectedScreen()));
          },
        ),
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalSpace = 32.0;
        const verticalSpace = 32.0;
        const phoneRatio = 390 / 844;
        final availableWidth = math.max(
          0.0,
          constraints.maxWidth - horizontalSpace,
        );
        final availableHeight = math.max(
          0.0,
          constraints.maxHeight - verticalSpace,
        );
        final width = math.min(
          390.0,
          math.min(availableWidth, availableHeight * phoneRatio),
        );
        final height = width / phoneRatio;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(44),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Column(
                children: [
                  Container(
                    height: 26,
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '9:41',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Container(
                          width: 54,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Icon(
                          Icons.battery_full,
                          size: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
