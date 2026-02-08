import 'package:baring_windows/onboarding/on_boarding_service.dart';
import 'package:baring_windows/onboarding/onboarding_page.dart';
import 'package:baring_windows/services/widget_service.dart';
import 'package:baring_windows/pages/home_page.dart';
import 'package:baring_windows/pages/profile_page.dart';
// import 'package:baring_windows/pages/dday_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  await Hive.initFlutter();

  await Hive.openBox('baring');

  // 위젯 초기화 ⭐
  await WidgetService.updateWidget(); // ⭐ 주석 해제

  // ⭐⭐⭐ 테스트용: 온보딩 리셋 (테스트 끝나면 삭제하세요!)
  // await OnboardingService.resetOnboarding();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // int _selectedIndex = 0;
  // final List<Widget> _pages = [
  //   const HomePage(),
  //   // const DDaySettingsPage(),
  //   const ProfilePage(),
  // ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const InitialScreen(),
    );
  }
}

// 앱 시작 시 온보딩 완료 여부를 확인하는 화면
class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  void _checkOnboardingStatus() {
    // Hive는 동기적으로 읽을 수 있습니다
    final hasSeenOnboarding = OnboardingService.hasSeenOnboarding();

    // 약간의 딜레이 후 화면 전환
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      if (hasSeenOnboarding) {
        // 온보딩을 이미 본 경우 -> 메인 화면으로
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainAppScreen()),
        );
      } else {
        // 온보딩을 처음 보는 경우 -> 온보딩 화면으로
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 화면 (온보딩 확인 중)
    return const Scaffold(
      backgroundColor: Color(0xFF050A12),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF3E7BFF))),
    );
  }
}

// 메인 앱 화면 (BottomNavigationBar 포함) - 기존 코드 그대로
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const HomePage(),
    // const DDaySettingsPage(),
    const ProfilePage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: null,
        scaffoldBackgroundColor: Color(0xFF0B1623),
      ),

      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [const Locale('ko', 'KR')],
      debugShowCheckedModeBanner: false,

      home: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: _pages,
        ),

        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Color(0xFF0B1623),
          selectedItemColor: Colors.white,
          currentIndex: _selectedIndex,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
            // BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ""),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
          ],
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
      ),
    );
  }
}
