import 'package:flutter/material.dart';
import 'screens/folders/folder_explorer_screen.dart';
import 'screens/tools/teacher_tools_screen.dart';
import 'screens/ai/teacher_ai_screen.dart';

void main() {
  runApp(const AsatezahApp());
}

typedef RootScreen = MainTeacherNavScreen;

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
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const MainTeacherNavScreen(),
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
    FolderExplorerScreen(),
    TeacherToolsScreen(),
    TeacherAiScreen(),
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
