import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;

class WidgetService {
  static bool _appGroupSet = false;
  static Future<void>? _pendingFuture;

  /// pending 토글 처리 완료 시 증가 → 리스너가 데이터 리로드
  static final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

  static Future<void> _ensureAppGroup() async {
    if (!_appGroupSet && Platform.isIOS) {
      await HomeWidget.setAppGroupId('group.baringWidget');
      _appGroupSet = true;
    }
  }

  /// 앱 접속 시간을 Hive + HomeWidget 공유 데이터에 저장
  static Future<void> saveLastAppOpen() async {
    try {
      await _ensureAppGroup();
      final now = DateTime.now().toIso8601String();
      final baringBox = Hive.box("baring");
      baringBox.put("lastAppOpen", now);
      await HomeWidget.saveWidgetData<String>('last_app_open', now);
    } catch (e) {
      print('lastAppOpen 저장 오류: $e');
    }
  }

  /// lastAppOpen에서 3일 경과 여부 계산 → widget_face 키에 저장
  static Future<void> updateWidgetFace() async {
    try {
      await _ensureAppGroup();
      final baringBox = Hive.box("baring");
      final lastOpenStr = baringBox.get("lastAppOpen");

      String face = "cheering2_face";
      if (lastOpenStr != null) {
        final lastOpen = DateTime.parse(lastOpenStr);
        final now = DateTime.now();
        final diff = now.difference(lastOpen).inDays;
        if (diff >= 3) {
          face = "disappointed_face";
        }
      }
      await HomeWidget.saveWidgetData<String>('widget_face', face);
    } catch (e) {
      print('위젯 표정 업데이트 오류: $e');
    }
  }

  static Future<void> updateWidget() async {
    try {
      await _ensureAppGroup();
      final baringBox = Hive.box("baring");
      final rawCards = baringBox.get("eventCards");
      final eventData = rawCards != null && (rawCards as List).isNotEmpty
          ? Map<String, dynamic>.from(rawCards.first)
          : null;

      String formatDate(DateTime date) {
        return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
      }

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

        // 위젯에 모든 데이터 전달 (첫 번째 목표 - 작은 위젯용)
        await HomeWidget.saveWidgetData<String>('title_text', title);
        await HomeWidget.saveWidgetData<String>('dday_text', dDayText);
        await HomeWidget.saveWidgetData<String>('percent_text', '$percent%');
        await HomeWidget.saveWidgetData<int>('progress', percent);
        await HomeWidget.saveWidgetData<String>('start_date', formatDate(startDate));
        await HomeWidget.saveWidgetData<String>('target_date', formatDate(targetDate));
        await HomeWidget.saveWidgetData<int>('selected_preset', selectedPreset);
      }

      // 모든 목표 저장 (큰 위젯 - 전체 목표 표시용)
      final cards = rawCards != null
          ? (rawCards as List).map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      final allGoalsList = cards.map((card) {
        final s = DateTime.parse(card["startDate"]);
        final t = DateTime.parse(card["targetDate"]);
        final daysRemaining = _calculateDays(t);
        final percent = _calculatePercent(s, t);
        final dDayText = daysRemaining > 0
            ? "D-$daysRemaining"
            : daysRemaining == 0
            ? "D-DAY"
            : "완료";
        return {
          'title': card["title"] ?? "목표 설정",
          'start_date': formatDate(s),
          'target_date': formatDate(t),
          'preset': card["selectedPreset"] ?? 0,
          'dday_text': dDayText,
          'percent': percent,
        };
      }).toList();
      await HomeWidget.saveWidgetData<String>('all_goals_json', jsonEncode(allGoalsList));

      // 위치 저장 (날씨 위젯용)
      await _saveLocationForWidget();

      // 날짜와 날씨 데이터 저장
      await _saveDateAndWeather();

      // 표정 업데이트
      await updateWidgetFace();

      // 플랫폼별 위젯 업데이트 (4x2 + 2x2)
      if (Platform.isAndroid) {
        await HomeWidget.updateWidget(androidName: 'HomeWidgetProvider');
        await HomeWidget.updateWidget(androidName: 'SmallHomeWidgetProvider');
      } else if (Platform.isIOS) {
        await HomeWidget.updateWidget(iOSName: 'BaringWidget');
        await HomeWidget.updateWidget(iOSName: 'BaringSmallWidget');
      }
    } catch (e) {
      print('위젯 업데이트 오류: $e');
    }
  }

  static Future<void> _saveLocationForWidget() async {
    try {
      await _ensureAppGroup();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return; // 위젯에서 서울 기본값 사용
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      await HomeWidget.saveWidgetData<double>('widget_lat', position.latitude);
      await HomeWidget.saveWidgetData<double>('widget_lon', position.longitude);
    } catch (e) {
      print('위치 저장 오류: $e');
    }
  }

  /// 날짜와 날씨 정보를 위젯에 저장
  static Future<void> _saveDateAndWeather() async {
    try {
      await _ensureAppGroup();

      // 날짜 텍스트 생성 (예: "5월 9일 (토)")
      final now = DateTime.now();
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final weekday = weekdays[now.weekday - 1];
      final dateText = '${now.month}월 ${now.day}일 ($weekday)';

      await HomeWidget.saveWidgetData<String>('date_text', dateText);

      // 날씨 정보는 추후 API 연동 (임시로 빈 문자열)
      // TODO: 날씨 API 연동
      final baringBox = Hive.box("baring");
      final weatherInfo = baringBox.get("weather_info"); // 이미 저장된 날씨 정보가 있다면

      if (weatherInfo != null && weatherInfo is Map) {
        final temp = weatherInfo['temp'];
        final icon = weatherInfo['icon'] ?? '☀️';
        final weatherText = temp != null ? '$icon ${temp}°' : '';
        await HomeWidget.saveWidgetData<String>('weather_text', weatherText);
      } else {
        // 기본값
        await HomeWidget.saveWidgetData<String>('weather_text', '');
      }
    } catch (e) {
      print('날짜/날씨 저장 오류: $e');
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
      await _ensureAppGroup();
      final baringBox = Hive.box("baring");
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final weekday = DateTime.now().weekday; // 1=월 ~ 7=일

      // ⭐ 전체 todos와 routines 데이터를 SharedDefaults에 저장 (iOS 위젯이 자정에 날짜별 필터링하기 위함)
      final todoRaw = baringBox.get('todos');
      final routineRaw = baringBox.get('routines');

      if (todoRaw != null) {
        final Map data = todoRaw is String ? jsonDecode(todoRaw) : Map.from(todoRaw);
        await HomeWidget.saveWidgetData<String>('all_todos_json', jsonEncode(data));
      } else {
        await HomeWidget.saveWidgetData<String>('all_todos_json', '{}');
      }

      if (routineRaw != null) {
        final allRoutines = (routineRaw as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        await HomeWidget.saveWidgetData<String>('all_routines_json', jsonEncode(allRoutines));
      } else {
        await HomeWidget.saveWidgetData<String>('all_routines_json', '[]');
      }

      // 현재 날짜 저장 (위젯이 마지막 업데이트된 날짜 확인용)
      await HomeWidget.saveWidgetData<String>('widget_last_update_date', todayKey);

      List<Map<String, dynamic>> items = [];
      int totalCount = 0;

      // 미완료 루틴 (먼저)
      if (routineRaw != null) {
        final allRoutines = (routineRaw as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        for (int i = 0; i < allRoutines.length; i++) {
          final routine = allRoutines[i];
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
              items.add({
                'type': 'routine',
                'title': routine['title'] ?? '',
                'routineId': (routine['id'] ?? '').toString(),
              });
            }
          }
        }
      }

      // 미완료 할 일 (그 다음)
      if (todoRaw != null) {
        final Map data = todoRaw is String ? jsonDecode(todoRaw) : Map.from(todoRaw);
        final todayTodos = data[todayKey];
        if (todayTodos != null) {
          final todoList = todayTodos as List;
          for (int i = 0; i < todoList.length; i++) {
            totalCount++;
            final todoMap = Map<String, dynamic>.from(todoList[i]);
            if (todoMap['done'] != true) {
              final item = <String, dynamic>{
                'type': 'todo',
                'title': todoMap['title'] ?? '',
                'todoIndex': i,
              };
              if (todoMap['time'] != null) item['time'] = todoMap['time'];
              items.add(item);
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

  /// 위젯에서 아이템 탭 시 완료 처리 (백그라운드 콜백에서 호출)
  /// pending 토글에 저장 후 위젯 데이터를 즉시 업데이트
  static Future<void> toggleWidgetItem(Uri? uri) async {
    if (uri == null) return;
    try {
      if (Platform.isIOS) {
        await HomeWidget.setAppGroupId('group.baringWidget');
      }

      final type = uri.queryParameters['type'];
      if (type == null) return;

      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 1. pending 토글 저장 (앱 복귀 시 Hive 동기화용)
      final pendingStr =
          await HomeWidget.getWidgetData<String>('pending_widget_toggles') ??
              '[]';
      final pendingList = List<Map<String, dynamic>>.from(
        (jsonDecode(pendingStr) as List)
            .map((e) => Map<String, dynamic>.from(e)),
      );
      final toggleInfo = <String, dynamic>{'type': type, 'date': todayKey};
      if (type == 'routine') {
        toggleInfo['routineId'] = uri.queryParameters['routineId'];
      } else if (type == 'todo') {
        toggleInfo['todoIndex'] =
            int.tryParse(uri.queryParameters['todoIndex'] ?? '');
      }
      pendingList.add(toggleInfo);
      await HomeWidget.saveWidgetData<String>(
          'pending_widget_toggles', jsonEncode(pendingList));

      // 2. 위젯 SharedPreferences에서 현재 아이템 리스트 업데이트
      final jsonStr =
          await HomeWidget.getWidgetData<String>('widget_items_json') ?? '[]';
      final items = List<Map<String, dynamic>>.from(
        (jsonDecode(jsonStr) as List)
            .map((e) => Map<String, dynamic>.from(e)),
      );

      // 3. 해당 아이템 제거
      if (type == 'routine') {
        final routineId = uri.queryParameters['routineId'];
        items.removeWhere((item) =>
            item['type'] == 'routine' &&
            (item['routineId'] ?? '').toString() == routineId);
      } else if (type == 'todo') {
        final todoIndexStr = uri.queryParameters['todoIndex'];
        items.removeWhere((item) =>
            item['type'] == 'todo' &&
            (item['todoIndex'] ?? '').toString() == todoIndexStr);
      }

      // 4. 업데이트된 아이템 저장
      await HomeWidget.saveWidgetData<String>(
          'widget_items_json', jsonEncode(items));
      await HomeWidget.saveWidgetData<int>('widget_items_count', items.length);

      // 5. 위젯 강제 갱신 (iOS와 Android 모두)
      if (Platform.isAndroid) {
        await HomeWidget.updateWidget(androidName: 'TodoWidgetProvider');
      } else if (Platform.isIOS) {
        await HomeWidget.updateWidget(iOSName: 'TodoWidget');
      }

      // 추가: 위젯이 바로 갱신되도록 타임라인 리로드 요청
      await HomeWidget.updateWidget();

    } catch (e) {
      print('위젯 아이템 토글 오류: $e');
    }
  }

  /// 앱 복귀 시 pending 토글을 Hive에 반영 (Android + iOS 공통)
  /// 여러 곳에서 동시 호출 시, 같은 Future를 공유하여 모두 완료를 기다림
  static Future<void> processPendingToggles() {
    _pendingFuture ??=
        _processPendingTogglesImpl().whenComplete(() => _pendingFuture = null);
    return _pendingFuture!;
  }

  static Future<void> _processPendingTogglesImpl() async {
    try {
      await _ensureAppGroup();
      final pendingJson =
          await HomeWidget.getWidgetData<String>('pending_widget_toggles');
      if (pendingJson == null || pendingJson.isEmpty || pendingJson == '[]') {
        return;
      }

      final List pendingList = jsonDecode(pendingJson);
      if (pendingList.isEmpty) return;

      final baringBox = Hive.box('baring');
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (final pending in pendingList) {
        final type = pending['type'];
        if (type == 'routine') {
          final routineId = pending['routineId']?.toString();
          if (routineId == null) continue;

          final routineRaw = baringBox.get('routines');
          if (routineRaw != null) {
            final allRoutines = (routineRaw as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            for (int i = 0; i < allRoutines.length; i++) {
              if ((allRoutines[i]['id'] ?? '').toString() == routineId) {
                final completions = Map<String, dynamic>.from(
                    allRoutines[i]['completions'] ?? {});
                completions[todayKey] = true;
                allRoutines[i]['completions'] = completions;
                break;
              }
            }
            await baringBox.put('routines', allRoutines);
          }
        } else if (type == 'todo') {
          final todoIndex = pending['todoIndex'] is int
              ? pending['todoIndex']
              : int.tryParse(pending['todoIndex']?.toString() ?? '');
          if (todoIndex == null) continue;

          final todoRaw = baringBox.get('todos');
          if (todoRaw != null) {
            final Map data = todoRaw is String
                ? jsonDecode(todoRaw)
                : Map.from(todoRaw);
            final todayTodos = data[todayKey];
            if (todayTodos != null) {
              final todoList = (todayTodos as List)
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
              if (todoIndex < todoList.length) {
                todoList[todoIndex]['done'] = true;
                data[todayKey] = todoList;
                await baringBox.put('todos', Map<String, dynamic>.from(
                  data.map((k, v) => MapEntry(k.toString(), v)),
                ));
              }
            }
          }
        }
      }

      // pending 초기화
      await HomeWidget.saveWidgetData<String>('pending_widget_toggles', '[]');

      // 위젯 재동기화 (Hive 데이터 기반)
      await syncWidget();

      // 리스너들에게 데이터 갱신 알림
      dataVersion.value++;
    } catch (e) {
      print('pending 토글 처리 오류: $e');
    }
  }
}
