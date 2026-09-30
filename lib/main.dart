import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/library/home_screen.dart';
import 'services/auth_service.dart';
import 'widgets/app_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة خدمة المصادقة قبل تشغيل التطبيق
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

  /// الاستعلام عن حالة الاتصال والاشتراك بالتغييرات
  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();

    try {
      final results = await connectivity.checkConnectivity();
      _updateOnlineStatus(results);
    } catch (_) {
      // تجاهل الأخطاء أثناء الاستعلام الأولي
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
      setState(() => _isOnline = isConnected);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أساتذة',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,

      // إعدادات اللغة العربية
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // تغليف التطبيق بالشريط العلوي وشريط الاتصال بشكل آمن
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AppTheme.primaryDark, // خلفية الشريط العلوي (Notch area)
            body: SafeArea(
              bottom: false, // لعدم اقتطاع الشاشة من الأسفل
              child: Column(
                children: [
                  // شريط الهوية العلوي
                  const _TopBrandBar(),

                  // شريط حالة الاتصال مع حركة انزلاق ناعمة
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: SizedBox(
                      height: _isOnline ? 0 : null,
                      width: double.infinity,
                      child: Container(
                        color: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: const Text(
                          'أنت غير متصل بالإنترنت',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // الشاشات الداخلية (مغلفة بـ MediaQuery لضمان عمل الكيبورد بسلاسة)
                  Expanded(
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        padding: EdgeInsets.zero, // منع تكرار SafeArea الداخلي
                      ),
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

// ==========================================
// مكون شريط الهوية العلوي
// ==========================================
class _TopBrandBar extends StatelessWidget {
  const _TopBrandBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 42,
      color: AppTheme.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppLogo(size: 28),
          SizedBox(width: 8),
          Text(
            'أساتذة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// RootScreen: توجيه المستخدم
// ==========================================
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
