import 'dart:io' show Platform;

import 'package:baring_windows/onboarding/on_boarding_service.dart';
import 'package:baring_windows/onboarding/onboarding_page.dart';
import 'package:baring_windows/services/widget_service.dart';
import 'package:baring_windows/pages/home_page.dart';
import 'package:baring_windows/pages/todo_page.dart';
import 'package:baring_windows/pages/profile_page.dart';
// import 'package:baring_windows/pages/dday_settings_page.dart';
import 'package:baring_windows/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  await Hive.initFlutter();

  await Hive.openBox('baring');

  // iOS App Group 설정 (위젯과 앱 간 데이터 공유에 필수) ⭐
  if (Platform.isIOS) {
    await HomeWidget.setAppGroupId('group.baringWidget');
  }

  // 위젯 초기화 ⭐
  await WidgetService.updateWidget(); // D-Day 위젯
  await WidgetService.syncWidget(); // 할 일 위젯

  // 알림 초기화
  await NotificationService.init();
  await NotificationService.refreshDailyNotifications();

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
  @override
  Widget build(BuildContext context) {
    final hasSeenOnboarding = OnboardingService.hasSeenOnboarding();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      home: hasSeenOnboarding
          ? const MainAppScreen()
          : const OnboardingPage(),
    );
  }
}

// 메인 앱 화면 (BottomNavigationBar 포함) - 기존 코드 그대로
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const HomePage(),
    const TodoPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아올 때 위젯 동기화
      WidgetService.updateWidget();
      WidgetService.syncWidget();
      NotificationService.refreshDailyNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "",
          ),
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
    );
  }
}
