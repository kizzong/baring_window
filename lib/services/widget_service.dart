import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;

class WidgetService {
  static Future<void> updateWidget() async {
    try {
      final baringBox = Hive.box("baring");
      final eventData = baringBox.get("eventCard");

      if (eventData != null) {
        final title = eventData["title"] ?? "목표 설정";
        final startDate = DateTime.parse(eventData["startDate"]);
        final targetDate = DateTime.parse(eventData["targetDate"]);
        final selectedPreset = eventData["selectedPreset"] ?? 0;
        final daysRemaining = _calculateDays(targetDate);
        final percent = _calculatePercent(startDate, targetDate);

        final dDayText = daysRemaining > 0
            ? "D-$daysRemaining"
            : daysRemaining == 0
            ? "D-DAY"
            : "완료";

        String formatDate(DateTime date) {
          return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
        }

        // 위젯에 모든 데이터 전달
        await HomeWidget.saveWidgetData<String>('title_text', title);
        await HomeWidget.saveWidgetData<String>('dday_text', dDayText);
        await HomeWidget.saveWidgetData<String>('percent_text', '$percent%');
        await HomeWidget.saveWidgetData<int>('progress', percent);
        await HomeWidget.saveWidgetData<String>(
          'start_date',
          formatDate(startDate),
        );
        await HomeWidget.saveWidgetData<String>(
          'target_date',
          formatDate(targetDate),
        );
        await HomeWidget.saveWidgetData<int>('selected_preset', selectedPreset);

        // 플랫폼별 위젯 업데이트
        if (Platform.isAndroid) {
          await HomeWidget.updateWidget(androidName: 'HomeWidgetProvider');
        } else if (Platform.isIOS) {
          await HomeWidget.updateWidget(iOSName: 'BaringWidget');
        }
      }
    } catch (e) {
      print('위젯 업데이트 오류: $e');
    }
  }

  static int _calculateDays(DateTime targetDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return end.difference(today).inDays;
  }

  static double _calculateProgress(DateTime startDate, DateTime targetDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final totalDays = end.difference(start).inDays;
    if (totalDays <= 0) return 1.0;

    final passedDays = today.difference(start).inDays;
    return (passedDays / totalDays).clamp(0.0, 1.0);
  }

  static int _calculatePercent(DateTime startDate, DateTime targetDate) {
    return (_calculateProgress(startDate, targetDate) * 100).round();
  }

  /// 오늘의 미완료 할 일 + 루틴을 홈 위젯에 동기화
  static Future<void> syncWidget() async {
    try {
      final baringBox = Hive.box("baring");
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final weekday = DateTime.now().weekday; // 1=월 ~ 7=일

      List<Map<String, String>> items = [];
      int totalCount = 0;

      // 미완료 루틴 (먼저)
      final routineRaw = baringBox.get('routines');
      if (routineRaw != null) {
        final allRoutines = (routineRaw as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        for (final routine in allRoutines) {
          bool isForToday = false;
          if (routine['type'] == 'daily') {
            isForToday = true;
          } else if (routine['type'] == 'weekly') {
            final days = List<int>.from(routine['days'] ?? []);
            isForToday = days.contains(weekday);
          }
          if (isForToday) {
            totalCount++;
            final completions =
                Map<String, dynamic>.from(routine['completions'] ?? {});
            if (completions[todayKey] != true) {
              items.add({'type': 'routine', 'title': routine['title'] ?? ''});
            }
          }
        }
      }

      // 미완료 할 일 (그 다음)
      final todoRaw = baringBox.get('todos');
      if (todoRaw != null) {
        final Map data = todoRaw is String ? jsonDecode(todoRaw) : Map.from(todoRaw);
        final todayTodos = data[todayKey];
        if (todayTodos != null) {
          for (final todo in (todayTodos as List)) {
            totalCount++;
            final todoMap = Map<String, dynamic>.from(todo);
            if (todoMap['done'] != true) {
              items.add({'type': 'todo', 'title': todoMap['title'] ?? ''});
            }
          }
        }
      }

      final jsonString = jsonEncode(items);
      await HomeWidget.saveWidgetData<String>('widget_items_json', jsonString);
      await HomeWidget.saveWidgetData<int>('widget_items_count', items.length);
      await HomeWidget.saveWidgetData<int>('widget_items_total', totalCount);

      if (Platform.isAndroid) {
        await HomeWidget.updateWidget(androidName: 'TodoWidgetProvider');
      } else if (Platform.isIOS) {
        await HomeWidget.updateWidget(iOSName: 'TodoWidget');
      }
    } catch (e) {
      print('할 일 위젯 업데이트 오류: $e');
    }
  }
}
