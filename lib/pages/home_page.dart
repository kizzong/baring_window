import 'dart:io';

import 'package:baring_windows/main.dart';
import 'package:baring_windows/pages/dday_settings_page.dart';
import 'package:baring_windows/services/notification_service.dart';
import 'package:baring_windows/services/widget_service.dart';
import 'package:baring_windows/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  Box baringBox = Hive.box("baring");

  late AnimationController _analysisAnimController;
  double _analysisFrom = 0.0;
  double _analysisTarget = 0.0;

  double get _analysisAnimValue {
    final t = Curves.easeOutCubic.transform(_analysisAnimController.value);
    return _analysisFrom + (_analysisTarget - _analysisFrom) * t;
  }

  @override
  void initState() {
    super.initState();
    _analysisAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    final data = _todayCompletion();
    final total = data['total']!;
    final completed = data['completed']!;
    _analysisFrom = 0.0;
    _analysisTarget = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    _analysisAnimController.forward();
  }

  @override
  void dispose() {
    _analysisAnimController.dispose();
    super.dispose();
  }

  // ── 오늘 진행도 계산 (할일 + 루틴) ──
  Map<String, int> _todayCompletion() {
    int completed = 0;
    int total = 0;

    // 할일
    final todos = _getTodayTodos();
    total += todos.length;
    completed += todos.where((t) => t['done'] == true).length;

    // 루틴
    final routines = _getTodayRoutines();
    total += routines.length;
    completed += routines.where((r) => _isRoutineCompletedToday(r)).length;

    return {'completed': completed, 'total': total};
  }

  void _refreshAnalysisAnim() {
    final data = _todayCompletion();
    final total = data['total']!;
    final completed = data['completed']!;
    _analysisFrom = _analysisAnimValue;
    _analysisTarget = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    _analysisAnimController
      ..reset()
      ..forward();
  }

  // 계산 함수들 추가
  int _calculateDays(DateTime targetDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return end.difference(today).inDays;
  }

  double _calculateProgress(DateTime startDate, DateTime targetDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final totalDays = end.difference(start).inDays;
    if (totalDays <= 0) return 1.0;

    final passedDays = today.difference(start).inDays;
    return (passedDays / totalDays).clamp(0.0, 1.0);
  }

  int _calculatePercent(DateTime startDate, DateTime targetDate) {
    return (_calculateProgress(startDate, targetDate) * 100).round();
  }

  static const _dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // ── 루틴 관련 ──

  List<Map<String, dynamic>> _getTodayRoutines() {
    final raw = baringBox.get('routines');
    if (raw == null) return [];
    final allRoutines = (raw as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final weekday = DateTime.now().weekday; // 1=월 ~ 7=일
    return allRoutines.where((r) {
      if (r['type'] == 'daily') return true;
      if (r['type'] == 'weekly') {
        final days = List<int>.from(r['days'] ?? []);
        return days.contains(weekday);
      }
      return false;
    }).toList();
  }

  bool _isRoutineCompletedToday(Map<String, dynamic> routine) {
    final completions = Map<String, dynamic>.from(routine['completions'] ?? {});
    return completions[_todayKey] == true;
  }

  void _toggleRoutine(int index) {
    final todayRoutines = _getTodayRoutines();
    if (index >= todayRoutines.length) return;

    final routine = todayRoutines[index];
    final routineId = routine['id'];

    // 전체 루틴 리스트에서 해당 루틴 찾기
    final raw = baringBox.get('routines');
    if (raw == null) return;
    final allRoutines = (raw as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final globalIndex = allRoutines.indexWhere((r) => r['id'] == routineId);
    if (globalIndex == -1) return;

    final completions = Map<String, dynamic>.from(
        allRoutines[globalIndex]['completions'] ?? {});
    completions[_todayKey] = !(completions[_todayKey] == true);
    allRoutines[globalIndex]['completions'] = completions;

    baringBox.put('routines', allRoutines);
    setState(() {});
    _refreshAnalysisAnim();
    WidgetService.syncWidget();
  }

  String _routineSubtitle(Map<String, dynamic> routine) {
    final type = routine['type'] as String;
    final time = routine['time'] as String?;
    final parts = <String>[];
    if (type == 'daily') {
      parts.add('매일');
    } else {
      final days = List<int>.from(routine['days'] ?? []);
      parts.add(days.map((d) => _dayNames[d - 1]).join(','));
    }
    if (time != null) parts.add(time);
    return parts.join(' · ');
  }

  List<Map<String, dynamic>> _getTodayTodos() {
    final raw = baringBox.get('todos');
    if (raw == null) return [];
    final Map data = Map.from(raw);
    final list = data[_todayKey];
    if (list == null) return [];
    return (list as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  int _currentStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final d = today.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      final weekday = d.weekday;

      // 해당 날짜 할일
      final rawTodos = baringBox.get('todos');
      final todosMap = rawTodos != null ? Map.from(rawTodos) : {};
      final todoList = todosMap[key] != null
          ? (todosMap[key] as List).map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];

      // 해당 날짜 루틴
      final rawRoutines = baringBox.get('routines');
      final allRoutines = rawRoutines != null
          ? (rawRoutines as List).map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      final dayRoutines = allRoutines.where((r) {
        if (r['type'] == 'daily') return true;
        if (r['type'] == 'weekly') return List<int>.from(r['days'] ?? []).contains(weekday);
        return false;
      }).toList();

      final total = todoList.length + dayRoutines.length;
      if (total == 0) continue; // 할일/루틴 없는 날은 스킵

      final completedTodos = todoList.where((t) => t['done'] == true).length;
      final completedRoutines = dayRoutines.where((r) {
        final comp = Map<String, dynamic>.from(r['completions'] ?? {});
        return comp[key] == true;
      }).length;

      if (completedTodos + completedRoutines == total) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  void _scheduleNotificationForTodo(int index, Map<String, dynamic> todo) {
    final time = todo['time'] as String?;
    final notifyBefore = todo['notifyBefore'] as int?;
    if (time == null || notifyBefore == null) return;

    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final date = DateTime.parse(_todayKey);
    final scheduledTime = DateTime(date.year, date.month, date.day, hour, minute)
        .subtract(Duration(minutes: notifyBefore));

    final id = NotificationService.generateId(_todayKey, index);
    NotificationService.scheduleNotification(
      id: id,
      title: todo['title'] ?? '',
      time: time,
      notifyBefore: notifyBefore,
      scheduledTime: scheduledTime,
    );
  }

  void _cancelNotificationForTodo(int index) {
    final id = NotificationService.generateId(_todayKey, index);
    NotificationService.cancelNotification(id);
  }

  void _performToggle(int index, Map<String, dynamic> todo, bool newDone) {
    final raw = baringBox.get('todos');
    if (raw == null) return;
    final Map data = Map.from(raw);
    final list = data[_todayKey];
    if (list == null || index >= (list as List).length) return;
    final todos = list.map((e) => Map<String, dynamic>.from(e)).toList();
    todos[index]['done'] = newDone;
    data[_todayKey] = todos;
    baringBox.put('todos', data);
    setState(() {});
    _refreshAnalysisAnim();
    WidgetService.syncWidget();
  }

  void _toggleTodo(int index) {
    final todos = _getTodayTodos();
    if (index >= todos.length) return;

    final todo = todos[index];
    final isDone = todo['done'] == true;
    final hasNotification = todo['time'] != null && todo['notifyBefore'] != null;

    // 알림 시간이 이미 지났는지 확인
    bool isTimePassed = false;
    if (hasNotification) {
      final now = DateTime.now();
      final parts = (todo['time'] as String).split(':');
      final todoDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      isTimePassed = todoDateTime.isBefore(now);
    }

    // 알림이 있는 할 일을 완료 체크하는 경우 → 확인 다이얼로그 (시간이 지났으면 바로 완료 처리)
    if (!isDone && hasNotification && !isTimePassed) {
      final notifyBefore = todo['notifyBefore'] as int;
      final notifyLabel = notifyBefore >= 60
          ? '${notifyBefore ~/ 60}시간 전'
          : '$notifyBefore분 전';

      final c = context.colors;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: c.dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '할 일 완료',
            style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          content: Text(
            '${todo['time']} ${todo['title']}\n\n'
            '설정된 알림($notifyLabel)이 취소됩니다.\n완료 처리하시겠습니까?',
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                '취소',
                style: TextStyle(color: c.textPrimary.withOpacity(0.5)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _performToggle(index, todo, true);
                _cancelNotificationForTodo(index);
              },
              child: Text(
                '완료',
                style: TextStyle(
                  color: c.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // 완료된 할 일을 체크 해제하는 경우 → 알림 재예약
    if (isDone && hasNotification) {
      _performToggle(index, todo, false);
      _scheduleNotificationForTodo(index, todo);
      return;
    }

    // 알림 시간이 지난 할 일 완료 → 다이얼로그 없이 바로 완료 처리
    if (!isDone && hasNotification && isTimePassed) {
      _performToggle(index, todo, true);
      _cancelNotificationForTodo(index);
      return;
    }

    // 알림 없는 할 일 → 기존 동작
    _performToggle(index, todo, !isDone);
  }

  void _addTodo(String title, {String? time, int? notifyBefore}) {
    final raw = baringBox.get('todos');
    final Map data = raw != null ? Map.from(raw) : {};
    final list = data[_todayKey];
    final todos = list != null
        ? (list as List).map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    final todo = <String, dynamic>{'title': title, 'done': false};
    if (time != null) todo['time'] = time;
    if (notifyBefore != null) todo['notifyBefore'] = notifyBefore;
    todos.add(todo);

    data[_todayKey] = todos;
    baringBox.put('todos', data);
    setState(() {});
    _refreshAnalysisAnim();
    WidgetService.syncWidget();

    if (time != null && notifyBefore != null) {
      _scheduleNotificationForTodo(todos.length - 1, todo);
    }
  }

  void _editTodo(int index, String title, {String? time, int? notifyBefore}) {
    final raw = baringBox.get('todos');
    if (raw == null) return;
    final Map data = Map.from(raw);
    final list = data[_todayKey];
    if (list == null || index >= (list as List).length) return;
    final todos = list.map((e) => Map<String, dynamic>.from(e)).toList();

    final old = todos[index];
    if (old['time'] != null && old['notifyBefore'] != null) {
      _cancelNotificationForTodo(index);
    }

    todos[index]['title'] = title;
    todos[index]['time'] = time;
    todos[index]['notifyBefore'] = notifyBefore;

    data[_todayKey] = todos;
    baringBox.put('todos', data);
    setState(() {});
    _refreshAnalysisAnim();
    WidgetService.syncWidget();

    if (time != null && notifyBefore != null) {
      _scheduleNotificationForTodo(index, todos[index]);
    }
  }

  void _editRoutine(int routineIndex, String title, {
    required String type,
    List<int>? days,
    String? time,
    int? notifyBefore,
  }) {
    final todayRoutines = _getTodayRoutines();
    if (routineIndex >= todayRoutines.length) return;
    final routine = todayRoutines[routineIndex];
    final routineId = routine['id'];

    final raw = baringBox.get('routines');
    if (raw == null) return;
    final allRoutines = (raw as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final globalIndex = allRoutines.indexWhere((r) => r['id'] == routineId);
    if (globalIndex == -1) return;

    allRoutines[globalIndex]['title'] = title;
    allRoutines[globalIndex]['type'] = type;
    if (type == 'weekly' && days != null) {
      allRoutines[globalIndex]['days'] = days;
    } else {
      allRoutines[globalIndex].remove('days');
    }
    allRoutines[globalIndex]['time'] = time;
    allRoutines[globalIndex]['notifyBefore'] = notifyBefore;

    baringBox.put('routines', allRoutines);
    setState(() {});
    _refreshAnalysisAnim();
    WidgetService.syncWidget();
  }

  void _deleteRoutine(int index) {
    final todayRoutines = _getTodayRoutines();
    if (index >= todayRoutines.length) return;
    final routine = todayRoutines[index];

    final c = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('루틴 삭제', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text(
          '"${routine['title']}" 루틴을 삭제하시겠습니까?',
          style: TextStyle(color: c.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소', style: TextStyle(color: c.textPrimary.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performDeleteRoutine(index);
            },
            child: const Text('삭제', style: TextStyle(color: Color(0xFFFF4D4D), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _performDeleteRoutine(int index) {
    final todayRoutines = _getTodayRoutines();
    if (index >= todayRoutines.length) return;
    final routine = todayRoutines[index];
    final routineId = routine['id'];

    final raw = baringBox.get('routines');
    if (raw == null) return;
    final allRoutines = (raw as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final globalIndex = allRoutines.indexWhere((r) => r['id'] == routineId);
    if (globalIndex == -1) return;

    final removed = allRoutines.removeAt(globalIndex);
    baringBox.put('routines', allRoutines);
    setState(() {});
    _refreshAnalysisAnim();
    WidgetService.syncWidget();

    final c = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${removed['title']}" 루틴 삭제됨',
          style: TextStyle(fontWeight: FontWeight.w600, color: c.textSecondary),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        backgroundColor: c.dialogBg,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: '되돌리기',
          textColor: c.primary,
          onPressed: () {
            final raw = baringBox.get('routines');
            final list = raw != null
                ? (raw as List).map((e) => Map<String, dynamic>.from(e)).toList()
                : <Map<String, dynamic>>[];
            list.insert(globalIndex.clamp(0, list.length), removed);
            baringBox.put('routines', list);
            setState(() {});
            _refreshAnalysisAnim();
            WidgetService.syncWidget();
          },
        ),
      ),
    );
  }

  void _deleteTodo(int index) {
    final todos = _getTodayTodos();
    if (index >= todos.length) return;
    final todo = todos[index];

    final c = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('할 일 삭제', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text(
          '"${todo['title']}" 할 일을 삭제하시겠습니까?',
          style: TextStyle(color: c.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소', style: TextStyle(color: c.textPrimary.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performDeleteTodo(index);
            },
            child: const Text('삭제', style: TextStyle(color: Color(0xFFFF4D4D), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _performDeleteTodo(int index) {
    final raw = baringBox.get('todos');
    if (raw == null) return;
    final Map data = Map.from(raw);
    final list = data[_todayKey];
    if (list == null || index >= (list as List).length) return;
    final todos = list.map((e) => Map<String, dynamic>.from(e)).toList();

    final removed = todos.removeAt(index);
    if (removed['time'] != null && removed['notifyBefore'] != null) {
      _cancelNotificationForTodo(index);
    }

    data[_todayKey] = todos;
    baringBox.put('todos', data);
    setState(() {});
    _refreshAnalysisAnim();
    WidgetService.syncWidget();

    final c = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${removed['title']}" 삭제됨',
          style: TextStyle(fontWeight: FontWeight.w600, color: c.textSecondary),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        backgroundColor: c.dialogBg,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: '되돌리기',
          textColor: c.primary,
          onPressed: () {
            final raw = baringBox.get('todos');
            final Map data = raw != null ? Map.from(raw) : {};
            final list = data[_todayKey];
            final todos = list != null
                ? (list as List).map((e) => Map<String, dynamic>.from(e)).toList()
                : <Map<String, dynamic>>[];
            todos.insert(index.clamp(0, todos.length), removed);
            data[_todayKey] = todos;
            baringBox.put('todos', data);
            setState(() {});
            _refreshAnalysisAnim();
            WidgetService.syncWidget();

            if (removed['time'] != null && removed['notifyBefore'] != null) {
              _scheduleNotificationForTodo(index, removed);
            }
          },
        ),
      ),
    );
  }

  // ── 순서 변경 ──

  void _reorderRoutine(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final todayRoutines = _getTodayRoutines();
    if (oldIndex >= todayRoutines.length || newIndex >= todayRoutines.length) return;

    final movedId = todayRoutines[oldIndex]['id'];
    final targetId = todayRoutines[newIndex]['id'];

    final raw = baringBox.get('routines');
    if (raw == null) return;
    final allRoutines = (raw as List).map((e) => Map<String, dynamic>.from(e)).toList();

    final fromGlobal = allRoutines.indexWhere((r) => r['id'] == movedId);
    final toGlobal = allRoutines.indexWhere((r) => r['id'] == targetId);
    if (fromGlobal == -1 || toGlobal == -1) return;

    final moved = allRoutines.removeAt(fromGlobal);
    allRoutines.insert(toGlobal, moved);

    baringBox.put('routines', allRoutines);
    setState(() {});
    WidgetService.syncWidget();
  }

  void _reorderTodo(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final raw = baringBox.get('todos');
    if (raw == null) return;
    final Map data = Map.from(raw);
    final list = data[_todayKey];
    if (list == null) return;
    final todos = (list as List).map((e) => Map<String, dynamic>.from(e)).toList();

    if (oldIndex >= todos.length || newIndex >= todos.length) return;

    final moved = todos.removeAt(oldIndex);
    todos.insert(newIndex, moved);

    data[_todayKey] = todos;
    baringBox.put('todos', data);
    setState(() {});
    WidgetService.syncWidget();
  }

  // ── 다이얼로그 ──

  void _showAddDialog() {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    TimeOfDay? selectedTime;
    int? selectedNotifyBefore;

    const notifyOptions = [
      {'label': '없음', 'value': null},
      {'label': '5분 전', 'value': 5},
      {'label': '10분 전', 'value': 10},
      {'label': '15분 전', 'value': 15},
      {'label': '30분 전', 'value': 30},
      {'label': '1시간 전', 'value': 60},
    ];

    final c = context.colors;
    showDialog(
      context: context,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 100), () {
          focusNode.requestFocus();
        });
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              if (controller.text.trim().isNotEmpty) {
                String? timeStr;
                if (selectedTime != null) {
                  timeStr = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                }
                _addTodo(controller.text.trim(), time: timeStr, notifyBefore: selectedTime != null ? selectedNotifyBefore : null);
                Navigator.pop(ctx);
              }
            }
            return GestureDetector(
              onTap: () => focusNode.unfocus(),
              child: AlertDialog(
                backgroundColor: c.dialogBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text('할 일 추가', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: true,
                        maxLength: 20,
                        style: TextStyle(color: c.textPrimary),
                        decoration: InputDecoration(
                          hintText: '할 일을 입력하세요',
                          hintStyle: TextStyle(color: c.textPrimary.withOpacity(0.4)),
                          counterStyle: TextStyle(color: c.textPrimary.withOpacity(0.4)),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.textPrimary.withOpacity(0.15))),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.primary)),
                        ),
                        onEditingComplete: () => focusNode.unfocus(),
                      ),
                      const SizedBox(height: 16),
                      _buildTimePickerButton(selectedTime: selectedTime, onTimeSelected: (t) => setDialogState(() => selectedTime = t), onTimeClear: () => setDialogState(() { selectedTime = null; selectedNotifyBefore = null; })),
                      if (selectedTime != null) ...[
                        const SizedBox(height: 12),
                        _buildNotifyOptions(notifyOptions: notifyOptions, selectedNotifyBefore: selectedNotifyBefore, onSelected: (v) => setDialogState(() => selectedNotifyBefore = v)),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('취소', style: TextStyle(color: c.textPrimary.withOpacity(0.5)))),
                  TextButton(onPressed: submit, child: Text('추가', style: TextStyle(color: c.primary, fontWeight: FontWeight.w700))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditTodoDialog(int index) {
    final todos = _getTodayTodos();
    if (index >= todos.length) return;
    final todo = todos[index];

    final controller = TextEditingController(text: todo['title'] ?? '');
    final focusNode = FocusNode();
    TimeOfDay? selectedTime;
    if (todo['time'] != null) {
      final parts = (todo['time'] as String).split(':');
      selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    int? selectedNotifyBefore = todo['notifyBefore'] as int?;

    const notifyOptions = [
      {'label': '없음', 'value': null},
      {'label': '5분 전', 'value': 5},
      {'label': '10분 전', 'value': 10},
      {'label': '15분 전', 'value': 15},
      {'label': '30분 전', 'value': 30},
      {'label': '1시간 전', 'value': 60},
    ];

    final c = context.colors;
    showDialog(
      context: context,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 100), () {
          focusNode.requestFocus();
        });
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              if (controller.text.trim().isNotEmpty) {
                String? timeStr;
                if (selectedTime != null) {
                  timeStr = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                }
                _editTodo(index, controller.text.trim(), time: timeStr, notifyBefore: selectedTime != null ? selectedNotifyBefore : null);
                Navigator.pop(ctx);
              }
            }
            return GestureDetector(
              onTap: () => focusNode.unfocus(),
              child: AlertDialog(
                backgroundColor: c.dialogBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text('할 일 수정', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: true,
                        maxLength: 20,
                        style: TextStyle(color: c.textPrimary),
                        decoration: InputDecoration(
                          hintText: '할 일을 입력하세요',
                          hintStyle: TextStyle(color: c.textPrimary.withOpacity(0.4)),
                          counterStyle: TextStyle(color: c.textPrimary.withOpacity(0.4)),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.textPrimary.withOpacity(0.15))),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.primary)),
                        ),
                        onEditingComplete: () => focusNode.unfocus(),
                      ),
                      const SizedBox(height: 16),
                      _buildTimePickerButton(selectedTime: selectedTime, onTimeSelected: (t) => setDialogState(() => selectedTime = t), onTimeClear: () => setDialogState(() { selectedTime = null; selectedNotifyBefore = null; })),
                      if (selectedTime != null) ...[
                        const SizedBox(height: 12),
                        _buildNotifyOptions(notifyOptions: notifyOptions, selectedNotifyBefore: selectedNotifyBefore, onSelected: (v) => setDialogState(() => selectedNotifyBefore = v)),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('취소', style: TextStyle(color: c.textPrimary.withOpacity(0.5)))),
                  TextButton(onPressed: submit, child: Text('수정', style: TextStyle(color: c.primary, fontWeight: FontWeight.w700))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditRoutineDialog(int routineIndex) {
    final todayRoutines = _getTodayRoutines();
    if (routineIndex >= todayRoutines.length) return;
    final routine = todayRoutines[routineIndex];

    final controller = TextEditingController(text: routine['title'] ?? '');
    final focusNode = FocusNode();
    String routineType = routine['type'] as String? ?? 'daily';
    List<int> selectedDays = List<int>.from(routine['days'] ?? []);
    TimeOfDay? selectedTime;
    if (routine['time'] != null) {
      final parts = (routine['time'] as String).split(':');
      selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    int? selectedNotifyBefore = routine['notifyBefore'] as int?;

    const notifyOptions = [
      {'label': '없음', 'value': null},
      {'label': '5분 전', 'value': 5},
      {'label': '10분 전', 'value': 10},
      {'label': '15분 전', 'value': 15},
      {'label': '30분 전', 'value': 30},
      {'label': '1시간 전', 'value': 60},
    ];

    final c = context.colors;
    showDialog(
      context: context,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 100), () {
          focusNode.requestFocus();
        });
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final title = controller.text.trim();
              if (title.isEmpty) return;
              if (routineType == 'weekly' && selectedDays.isEmpty) return;
              String? timeStr;
              if (selectedTime != null) {
                timeStr = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
              }
              _editRoutine(routineIndex, title, type: routineType, days: routineType == 'weekly' ? (List<int>.from(selectedDays)..sort()) : null, time: timeStr, notifyBefore: selectedTime != null ? selectedNotifyBefore : null);
              Navigator.pop(ctx);
            }
            return GestureDetector(
              onTap: () => focusNode.unfocus(),
              child: AlertDialog(
                backgroundColor: c.dialogBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text('루틴 수정', style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: true,
                        maxLength: 20,
                        style: TextStyle(color: c.textPrimary),
                        decoration: InputDecoration(
                          hintText: '루틴 이름을 입력하세요',
                          hintStyle: TextStyle(color: c.textPrimary.withOpacity(0.4)),
                          counterStyle: TextStyle(color: c.textPrimary.withOpacity(0.4)),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.textPrimary.withOpacity(0.15))),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.primary)),
                        ),
                        onEditingComplete: () => focusNode.unfocus(),
                      ),
                      const SizedBox(height: 16),
                      Text('반복', style: TextStyle(color: c.textPrimary.withOpacity(0.6), fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() { routineType = 'daily'; selectedDays = []; }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: routineType == 'daily' ? c.primary.withOpacity(0.2) : c.textPrimary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: routineType == 'daily' ? c.primary : c.textPrimary.withOpacity(0.1)),
                                ),
                                child: Center(child: Text('매일', style: TextStyle(color: routineType == 'daily' ? c.primary : c.textPrimary.withOpacity(0.6), fontWeight: FontWeight.w700, fontSize: 14))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(() => routineType = 'weekly'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: routineType == 'weekly' ? c.primary.withOpacity(0.2) : c.textPrimary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: routineType == 'weekly' ? c.primary : c.textPrimary.withOpacity(0.1)),
                                ),
                                child: Center(child: Text('특정 요일', style: TextStyle(color: routineType == 'weekly' ? c.primary : c.textPrimary.withOpacity(0.6), fontWeight: FontWeight.w700, fontSize: 14))),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (routineType == 'weekly') ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(7, (i) {
                            final day = i + 1;
                            final isSelected = selectedDays.contains(day);
                            return GestureDetector(
                              onTap: () => setDialogState(() { if (isSelected) { selectedDays.remove(day); } else { selectedDays.add(day); } }),
                              child: Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: isSelected ? c.primary : c.textPrimary.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isSelected ? Colors.transparent : c.textPrimary.withOpacity(0.1)),
                                ),
                                child: Center(child: Text(_dayNames[i], style: TextStyle(color: isSelected ? Colors.white : c.textPrimary.withOpacity(0.5), fontWeight: FontWeight.w700, fontSize: 12))),
                              ),
                            );
                          }),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _buildTimePickerButton(selectedTime: selectedTime, onTimeSelected: (t) => setDialogState(() => selectedTime = t), onTimeClear: () => setDialogState(() { selectedTime = null; selectedNotifyBefore = null; })),
                      if (selectedTime != null) ...[
                        const SizedBox(height: 12),
                        _buildNotifyOptions(notifyOptions: notifyOptions, selectedNotifyBefore: selectedNotifyBefore, onSelected: (v) => setDialogState(() => selectedNotifyBefore = v)),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('취소', style: TextStyle(color: c.textPrimary.withOpacity(0.5)))),
                  TextButton(onPressed: submit, child: Text('수정', style: TextStyle(color: c.primary, fontWeight: FontWeight.w700))),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimePickerButton({
    required TimeOfDay? selectedTime,
    required void Function(TimeOfDay) onTimeSelected,
    required VoidCallback onTimeClear,
  }) {
    final c = context.colors;
    return GestureDetector(
      onTap: () async {
        DateTime tempTime = DateTime(2000, 1, 1, selectedTime?.hour ?? TimeOfDay.now().hour, selectedTime?.minute ?? TimeOfDay.now().minute);
        await showCupertinoModalPopup(
          context: context,
          builder: (pickerCtx) {
            return Container(
              height: 300,
              decoration: BoxDecoration(color: c.dialogBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(padding: EdgeInsets.zero, child: Text('취소', style: TextStyle(color: c.textPrimary.withOpacity(0.5), fontSize: 16)), onPressed: () => Navigator.pop(pickerCtx)),
                        CupertinoButton(padding: EdgeInsets.zero, child: Text('확인', style: TextStyle(color: c.primary, fontWeight: FontWeight.w700, fontSize: 16)), onPressed: () { onTimeSelected(TimeOfDay(hour: tempTime.hour, minute: tempTime.minute)); Navigator.pop(pickerCtx); }),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Localizations(
                      locale: const Locale('ko', 'KR'),
                      delegates: const [GlobalCupertinoLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
                      child: CupertinoTheme(
                        data: CupertinoThemeData(brightness: c.brightness, textTheme: CupertinoTextThemeData(dateTimePickerTextStyle: TextStyle(color: c.textPrimary, fontSize: 22))),
                        child: CupertinoDatePicker(mode: CupertinoDatePickerMode.time, initialDateTime: tempTime, use24hFormat: false, onDateTimeChanged: (dt) => tempTime = dt),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: c.textPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selectedTime != null ? c.primary.withOpacity(0.5) : c.textPrimary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, size: 20, color: selectedTime != null ? c.primary : c.textPrimary.withOpacity(0.4)),
            const SizedBox(width: 10),
            Text(
              selectedTime != null ? '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}' : '시간 선택 (선택사항)',
              style: TextStyle(color: selectedTime != null ? c.textPrimary : c.textPrimary.withOpacity(0.4), fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Spacer(),
            if (selectedTime != null) GestureDetector(onTap: onTimeClear, child: Icon(Icons.close, size: 18, color: c.textPrimary.withOpacity(0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifyOptions({
    required List<Map<String, Object?>> notifyOptions,
    required int? selectedNotifyBefore,
    required void Function(int?) onSelected,
  }) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('알림', style: TextStyle(color: c.textPrimary.withOpacity(0.6), fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: notifyOptions.map((option) {
            final value = option['value'] as int?;
            final isSelected = selectedNotifyBefore == value;
            return GestureDetector(
              onTap: () => onSelected(value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? c.primary.withOpacity(0.2) : c.textPrimary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? c.primary : c.textPrimary.withOpacity(0.1)),
                ),
                child: Text(option['label'] as String, style: TextStyle(color: isSelected ? c.primary : c.textPrimary.withOpacity(0.6), fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final userName = baringBox.get("userName", defaultValue: "바링"); // 이름 불러오기 ⭐
    final profileImagePath = baringBox.get("profileImagePath"); // 추가 ⭐

    final eventData = baringBox.get("eventCard");

    final title = eventData?["title"] ?? "목표를 설정해주세요";
    final startDate = eventData != null
        ? DateTime.parse(eventData["startDate"])
        : DateTime.now();
    final targetDate = eventData != null
        ? DateTime.parse(eventData["targetDate"])
        : DateTime.now().add(Duration(days: 100)); // 100일 후를 기본값으로
    final selectedPreset = eventData?["selectedPreset"] ?? 0;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          child: Column(
            children: [
              // 상단 프로필 및 날짜
              Row(
                children: [
                  // avatar
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: c.borderColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.textPrimary.withOpacity(0.10),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: profileImagePath != null
                          ? Image.file(
                              File(profileImagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: c.borderColor,
                                  child: Icon(
                                    Icons.person,
                                    color: c.textSecondary,
                                    size: 24,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: c.borderColor,
                              child: Icon(
                                Icons.person,
                                color: c.textSecondary,
                                size: 24,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} (${['일', '월', '화', '수', '목', '금', '토'][DateTime.now().weekday % 7]})",
                          style: TextStyle(
                            color: c.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$userName 님",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              EventCard(
                title: title,
                startDate: startDate,
                targetDate: targetDate,
                days: _calculateDays(targetDate),
                gradient:
                    presets[selectedPreset.clamp(0, presets.length - 1)].colors,
                progress: _calculateProgress(startDate, targetDate),
                percent: _calculatePercent(startDate, targetDate),
                onMoreTap: () async {
                  // test_page로 이동하고 돌아올 때 화면 새로고침
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DDaySettingsPage()),
                  );
                  setState(() {}); // 돌아왔을 때 데이터 새로고침
                },
              ),
              const SizedBox(height: 24),

              // 날짜 헤더
              Row(
                children: [
                  Text(
                    DateFormat('M월 d일 (E)', 'ko').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _showAddDialog,
                    icon: Icon(Icons.add, color: c.primary, size: 25),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 루틴
              Builder(
                builder: (context) {
                  final todayRoutines = _getTodayRoutines();
                  if (todayRoutines.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: c.cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: c.borderColor,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '루틴이 없습니다',
                          style: TextStyle(
                            color: c.textPrimary.withOpacity(0.3),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }
                  return ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todayRoutines.length,
                    onReorder: _reorderRoutine,
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        color: Colors.transparent,
                        elevation: 4,
                        shadowColor: Colors.black45,
                        borderRadius: BorderRadius.circular(18),
                        child: child,
                      );
                    },
                    itemBuilder: (context, i) {
                      final routine = todayRoutines[i];
                      final isDone = _isRoutineCompletedToday(routine);
                      final subtitle = _routineSubtitle(routine);
                      return Padding(
                        key: ValueKey(routine['id']),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _showEditRoutineDialog(i),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 5, 12, 5),
                            decoration: BoxDecoration(
                              color: c.cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: c.borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleRoutine(i),
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.repeat_rounded,
                                        size: 18,
                                        color: isDone
                                            ? c.textPrimary.withOpacity(0.3)
                                            : c.primary.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        height: 26,
                                        width: 26,
                                        decoration: BoxDecoration(
                                          color: isDone
                                              ? c.primary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDone
                                                ? Colors.transparent
                                                : c.textPrimary.withOpacity(0.18),
                                            width: 1.6,
                                          ),
                                        ),
                                        child: isDone
                                            ? const Icon(
                                                Icons.check,
                                                size: 18,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        routine['title'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          decoration: isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: isDone
                                              ? c.textPrimary.withOpacity(0.45)
                                              : c.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDone
                                              ? c.textPrimary.withOpacity(0.3)
                                              : c.textPrimary.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _deleteRoutine(i),
                                  icon: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: c.textPrimary.withOpacity(0.3),
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // 할 일
              Builder(
                builder: (context) {
                  final todayTodos = _getTodayTodos();
                  if (todayTodos.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: c.cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: c.borderColor,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '할 일이 없습니다',
                          style: TextStyle(
                            color: c.textPrimary.withOpacity(0.3),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }
                  return ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todayTodos.length,
                    onReorder: _reorderTodo,
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        color: Colors.transparent,
                        elevation: 4,
                        shadowColor: Colors.black45,
                        borderRadius: BorderRadius.circular(18),
                        child: child,
                      );
                    },
                    itemBuilder: (context, i) {
                      final todo = todayTodos[i];
                      final isDone = todo['done'] == true;
                      final timeStr = todo['time'] as String?;
                      final notifyBefore = todo['notifyBefore'] as int?;
                      return Padding(
                        key: ValueKey('todo_${todo['title']}_$i'),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _showEditTodoDialog(i),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 5, 12, 5),
                            decoration: BoxDecoration(
                              color: c.cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: c.borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleTodo(i),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    height: 26,
                                    width: 26,
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? c.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDone
                                            ? Colors.transparent
                                            : c.textPrimary.withOpacity(0.18),
                                        width: 1.6,
                                      ),
                                    ),
                                    child: isDone
                                        ? const Icon(
                                            Icons.check,
                                            size: 18,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        todo['title'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          decoration: isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: isDone
                                              ? c.textPrimary.withOpacity(0.45)
                                              : c.textPrimary,
                                        ),
                                      ),
                                      if (timeStr != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 13,
                                              color: isDone
                                                  ? c.textPrimary.withOpacity(0.3)
                                                  : c.primary.withOpacity(0.7),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              timeStr,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isDone
                                                    ? c.textPrimary.withOpacity(0.3)
                                                    : c.primary.withOpacity(0.7),
                                              ),
                                            ),
                                            if (notifyBefore != null) ...[
                                              const SizedBox(width: 6),
                                              Icon(
                                                Icons.notifications_active_outlined,
                                                size: 13,
                                                color: isDone
                                                    ? c.textPrimary.withOpacity(0.3)
                                                    : c.textPrimary.withOpacity(0.4),
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                notifyBefore >= 60
                                                    ? '${notifyBefore ~/ 60}시간 전'
                                                    : '$notifyBefore분 전',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDone
                                                      ? c.textPrimary.withOpacity(0.3)
                                                      : c.textPrimary.withOpacity(0.4),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _deleteTodo(i),
                                  icon: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: c.textPrimary.withOpacity(0.3),
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 60),

              //
              // 나의 목표 상황
              Row(
                children: [
                  Icon(Icons.bar_chart, color: c.textPrimary, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    '분석',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      context.findAncestorStateOfType<MainAppScreenState>()
                          ?.navigateToTab(2);
                    },
                    child: Text(
                      '자세히',
                      style: TextStyle(
                        color: c.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 목표 카드 상황
              Builder(
                builder: (context) {
                  final data = _todayCompletion();
                  final total = data['total']!;
                  final completed = data['completed']!;
                  final streak = _currentStreak();
                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: c.analysisBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: c.borderColor,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    SizedBox(height: 10),
                                    AnimatedBuilder(
                                      animation: _analysisAnimController,
                                      builder: (context, child) {
                                        final animValue = _analysisAnimValue;
                                        final animPercent = (animValue * 100).round();
                                        return SizedBox(
                                          height: 64,
                                          width: 64,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              SizedBox(
                                                height: 64,
                                                width: 64,
                                                child: CircularProgressIndicator(
                                                  value: 1,
                                                  strokeWidth: 7,
                                                  valueColor: AlwaysStoppedAnimation(
                                                    c.textPrimary.withOpacity(0.10),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: 64,
                                                width: 64,
                                                child: CircularProgressIndicator(
                                                  value: animValue,
                                                  strokeWidth: 7,
                                                  valueColor: AlwaysStoppedAnimation(
                                                    Color(0xFF22C55E),
                                                  ),
                                                  backgroundColor: Colors.transparent,
                                                ),
                                              ),
                                              Text(
                                                "$animPercent%",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      "오늘 진행도",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "$completed/$total",
                                      style: TextStyle(
                                        color: c.textPrimary.withOpacity(0.55),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: c.analysisBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: c.borderColor,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 64,
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.local_fire_department,
                                          size: 30,
                                          color: streak > 0 ? const Color(0xFFF97316) : c.textPrimary.withOpacity(0.3),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          streak > 0 ? "$streak일" : "-",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 30,
                                            color: streak > 0 ? const Color(0xFFF59E0B) : c.textPrimary.withOpacity(0.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "연속 달성",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  streak > 0 ? "연속 달성 중!" : "오늘 도전하세요",
                                  style: TextStyle(
                                    color: c.textPrimary.withOpacity(0.55),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
