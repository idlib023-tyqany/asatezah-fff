import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import './core/theme/app_theme.dart';
import './features/auth/auth_service.dart';
import './features/auth/login/login_screen.dart';
import './features/library/home/home_screen.dart';
import './core/widgets/app_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().init();
  runApp(const AsatezahApp());
}

class AsatezahApp extends StatefulWidget {
  const AsatezahApp({super.key});

  @override
  State<AsatezahApp> createState() => _AsatezahAppState();
}

class _AsatezahAppState extends State<AsatezahApp> {
  bool _isOnline = true;
  StreamSubscription<dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();

    try {
      final results = await connectivity.checkConnectivity();
      _updateOnlineStatus(results);
    } catch (_) {
      // تجاهل الاستثناءات غير المتوقعة على بعض الأجهزة القديمة
    }

    _subscription = connectivity.onConnectivityChanged.listen(_updateOnlineStatus);
  }

  void _updateOnlineStatus(dynamic result) {
    bool isConnected = false;

    if (result is List<ConnectivityResult>) {
      isConnected = result.any((r) => r != ConnectivityResult.none);
    } else if (result is ConnectivityResult) {
      isConnected = result != ConnectivityResult.none;
    }

    if (_isOnline != isConnected) {
      if (mounted) {
        setState(() => _isOnline = isConnected);
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontFamily = GoogleFonts.cairo().fontFamily;
    final baseTextTheme = ThemeData.light().textTheme.apply(fontFamily: fontFamily);
    final darkTextTheme = ThemeData.dark().textTheme.apply(fontFamily: fontFamily);

    return MaterialApp(
      title: AppTheme.appName,
      theme: AppTheme.lightTheme.copyWith(
        textTheme: baseTextTheme,
        primaryTextTheme: baseTextTheme,
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        textTheme: darkTextTheme,
        primaryTextTheme: darkTextTheme,
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return AnimatedTheme(
          data: Theme.of(context),
          duration: const Duration(milliseconds: 250),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const _TopBrandBar(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: _isOnline ? 0 : 32,
                    width: double.infinity,
                    color: AppTheme.warningColor,
                    alignment: Alignment.center,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isOnline ? 0.0 : 1.0,
                      child: const Text(
                        'أنت غير متصل بالإنترنت',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      home: const RootScreen(),
    );
  }
}

class _TopBrandBar extends StatelessWidget {
  const _TopBrandBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      color: AppTheme.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppLogo(size: 28),
          SizedBox(width: 8),
          Text(
            'أساتذة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
