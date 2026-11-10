import 'package:flutter/material.dart';

import 'features/auth/auth_service.dart';
import 'features/auth/login/login_widget.dart';
import 'features/folder_explorer/folder_explorer_widget.dart';
import 'features/teacher_ai/teacher_ai_widget.dart';
import 'features/teacher_tools/teacher_tools_widget.dart';

void main() {
  runApp(const AsatezahApp());
}

class AsatezahApp extends StatelessWidget {
  const AsatezahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة أساتذة - ASATEZAH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        fontFamily: 'Cairo',
      ),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final AuthService _auth = AuthService();
  bool _isRestoringSession = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await _auth.init();
    if (mounted) setState(() => _isRestoringSession = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoringSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) => _auth.isAuthenticated
          ? const MainTeacherNavScreen()
          : const LoginScreen(),
    );
  }
}

class MainTeacherNavScreen extends StatefulWidget {
  const MainTeacherNavScreen({super.key});

  @override
  State<MainTeacherNavScreen> createState() => _MainTeacherNavScreenState();
}

class _MainTeacherNavScreenState extends State<MainTeacherNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FolderExplorerWidget(),
    TeacherToolsWidget(),
    TeacherAiWidget(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_shared_outlined),
            selectedIcon: Icon(Icons.folder_shared_rounded),
            label: 'مجلدات الصفوف',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'جدولي وأدواتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'مساعد Gemini الذكي',
          ),
        ],
      ),
    );
  }
}
