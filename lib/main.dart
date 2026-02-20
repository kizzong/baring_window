import 'dart:io' show Platform;

import 'package:baring_windows/onboarding/on_boarding_service.dart';
import 'package:baring_windows/onboarding/onboarding_page.dart';
import 'package:baring_windows/services/widget_service.dart';
import 'package:baring_windows/pages/home_page.dart';
import 'package:baring_windows/pages/todo_page.dart';
import 'package:baring_windows/pages/analysis_page.dart';
import 'package:baring_windows/pages/profile_page.dart';
// import 'package:baring_windows/pages/dday_settings_page.dart';
import 'package:baring_windows/services/notification_service.dart';
import 'package:baring_windows/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';

/// 전역 다크모드 상태
final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  await Hive.initFlutter();

  await Hive.openBox('baring');

  // Hive에서 다크모드 설정 로드
  final box = Hive.box('baring');
  isDarkMode.value = box.get('isDarkMode', defaultValue: true);

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

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, _) {
        final appColors = dark ? AppColors.dark : AppColors.light;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
            fontFamily: null,
            scaffoldBackgroundColor: appColors.scaffoldBg,
            extensions: [appColors],
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
      },
    );
  }
}

// 메인 앱 화면 (BottomNavigationBar 포함) - 기존 코드 그대로
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => MainAppScreenState();
}

class MainAppScreenState extends State<MainAppScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void navigateToTab(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  final List<Widget> _pages = [
    const HomePage(),
    const TodoPage(),
    const AnalysisPage(),
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
    final c = context.colors;

    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = _pageController.page! - index;
                value = (1 - value.abs()).clamp(0.0, 1.0);
              } else {
                value = index == _selectedIndex ? 1.0 : 0.0;
              }
              final scale = 0.95 + (0.05 * value);
              final opacity = value.clamp(0.0, 1.0);
              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              );
            },
            child: _pages[index],
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: c.bottomNavBg,
        selectedItemColor: c.textPrimary,
        unselectedItemColor: c.textSecondary,
        currentIndex: _selectedIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ""),
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
