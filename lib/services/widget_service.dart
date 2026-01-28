import 'package:home_widget/home_widget.dart';
import 'package:hive/hive.dart';
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
}
