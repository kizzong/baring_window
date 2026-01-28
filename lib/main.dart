import 'package:baring_windows/services/widget_service.dart';
import 'package:baring_windows/pages/home_page.dart';
import 'package:baring_windows/pages/profile_page.dart';
import 'package:baring_windows/pages/dday_settings_page.dart';
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
  await WidgetService.updateWidget();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    // const DDaySettingsPage(),
    const ProfilePage(),
  ];

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
        body: _pages[_selectedIndex],

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
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
