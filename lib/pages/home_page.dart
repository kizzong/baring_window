import 'dart:io';

import 'package:baring_windows/pages/dday_settings_page.dart';
import 'package:baring_windows/services/notification_service.dart';
import 'package:baring_windows/services/widget_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Box baringBox = Hive.box("baring");
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

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

  String _dayKey(DateTime day) => DateFormat('yyyy-MM-dd').format(day);

  List<Map<String, dynamic>> _getTodosForDay(DateTime day) {
    final raw = baringBox.get('todos');
    if (raw == null) return [];
    final Map data = Map.from(raw);
    final list = data[_dayKey(day)];
    if (list == null) return [];
    return (list as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  List<Map<String, dynamic>> _getRoutinesForDay(DateTime day) {
    final raw = baringBox.get('routines');
    if (raw == null) return [];
    final allRoutines = (raw as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final weekday = day.weekday;
    return allRoutines.where((r) {
      if (r['type'] == 'daily') return true;
      if (r['type'] == 'weekly') {
        final days = List<int>.from(r['days'] ?? []);
        return days.contains(weekday);
      }
      return false;
    }).toList();
  }

  Widget _buildCalendarCell(DateTime day, {
    required bool isSelected,
    required bool isToday,
    bool isWeekend = false,
  }) {
    final todos = _getTodosForDay(day);
    final routines = _getRoutinesForDay(day);

    final allItems = <({String title, String? time, bool hasAlarm, Color color})>[];
    for (final r in routines) {
      allItems.add((
        title: r['title'] ?? '',
        time: null,
        hasAlarm: false,
        color: const Color(0xFF22C55E),
      ));
    }
    for (final t in todos) {
      allItems.add((
        title: t['title'] ?? '',
        time: t['time'] as String?,
        hasAlarm: t['notifyBefore'] != null,
        color: const Color(0xFF2D86FF),
      ));
    }

    final TextStyle dateTextStyle;
    if (isSelected) {
      dateTextStyle = const TextStyle(
        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14,
      );
    } else if (isToday) {
      dateTextStyle = const TextStyle(
        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14,
      );
    } else if (isWeekend) {
      dateTextStyle = TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontWeight: FontWeight.w600, fontSize: 14,
      );
    } else {
      dateTextStyle = const TextStyle(
        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14,
      );
    }

    BoxDecoration? dateDecoration;
    if (isSelected) {
      dateDecoration = const BoxDecoration(
        color: Color(0xFF2D86FF), shape: BoxShape.circle,
      );
    } else if (isToday) {
      dateDecoration = BoxDecoration(
        color: const Color(0xFF2D86FF).withOpacity(0.3),
        shape: BoxShape.circle,
      );
    }

    const int maxVisible = 3;
    final int remainingCount =
        allItems.length > maxVisible ? allItems.length - maxVisible : 0;
    final visibleItems = allItems.take(maxVisible).toList();

    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Container(
            width: 28, height: 28,
            decoration: dateDecoration,
            alignment: Alignment.center,
            child: Text('${day.day}', style: dateTextStyle),
          ),
          const SizedBox(height: 2),
          ...visibleItems.map((item) => Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: item.color, height: 1.2,
                  ),
                ),
                if (item.time != null)
                  Row(
                    children: [
                      Text(
                        item.time!,
                        style: TextStyle(
                          fontSize: 8, fontWeight: FontWeight.w500,
                          color: item.color.withOpacity(0.7), height: 1.2,
                        ),
                      ),
                      if (item.hasAlarm) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 8,
                          color: item.color.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          )),
          if (remainingCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '+$remainingCount',
                style: TextStyle(
                  fontSize: 8, fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.4), height: 1.2,
                ),
              ),
            ),
        ],
      ),
    );
  }

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
    WidgetService.syncWidget();
  }

  void _toggleTodo(int index) {
    final todos = _getTodayTodos();
    if (index >= todos.length) return;

    final todo = todos[index];
    final isDone = todo['done'] == true;
    final hasNotification = todo['time'] != null && todo['notifyBefore'] != null;

    // 알림이 있는 할 일을 완료 체크하는 경우 → 확인 다이얼로그
    if (!isDone && hasNotification) {
      final notifyBefore = todo['notifyBefore'] as int;
      final notifyLabel = notifyBefore >= 60
          ? '${notifyBefore ~/ 60}시간 전'
          : '$notifyBefore분 전';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '할 일 완료',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          content: Text(
            '${todo['time']} ${todo['title']}\n\n'
            '설정된 알림($notifyLabel)이 취소됩니다.\n완료 처리하시겠습니까?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                '취소',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _performToggle(index, todo, true);
                _cancelNotificationForTodo(index);
              },
              child: const Text(
                '완료',
                style: TextStyle(
                  color: Color(0xFF2D86FF),
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

    // 알림 없는 할 일 → 기존 동작
    _performToggle(index, todo, !isDone);
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: Color(0xFF0B1623),
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
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.10),
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
                                  color: Colors.white.withOpacity(0.08),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white70,
                                    size: 24,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.white.withOpacity(0.08),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white70,
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
                            color: Colors.white.withValues(alpha: 0.65),
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

              // 캘린더
              TableCalendar(
                locale: 'ko_KR',
                rowHeight: 120,
                availableGestures: AvailableGestures.none,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: '월',
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final isWeekend = day.weekday == DateTime.saturday ||
                        day.weekday == DateTime.sunday;
                    return _buildCalendarCell(day,
                      isSelected: false, isToday: false, isWeekend: isWeekend,
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return _buildCalendarCell(day,
                      isSelected: false, isToday: true,
                    );
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return _buildCalendarCell(day,
                      isSelected: true,
                      isToday: isSameDay(day, DateTime.now()),
                    );
                  },
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  cellMargin: const EdgeInsets.all(1),
                  defaultTextStyle: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600,
                  ),
                  weekendTextStyle: const TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600,
                  ),
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF2D86FF).withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFF2D86FF), shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700,
                  ),
                  markersMaxCount: 0,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
                  ),
                  leftChevronIcon: const Icon(
                    Icons.chevron_left, color: Colors.white,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right, color: Colors.white,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.w600, fontSize: 13,
                  ),
                  weekendStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.w600, fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 32),

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
                ],
              ),
              const SizedBox(height: 20),

              // 루틴
              Builder(
                builder: (context) {
                  final todayRoutines = _getTodayRoutines();
                  final routineDoneCount = todayRoutines
                      .where((r) => _isRoutineCompletedToday(r))
                      .length;
                  return Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.repeat_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "루틴",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          if (todayRoutines.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F2538),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                              child: Text(
                                '$routineDoneCount/${todayRoutines.length}',
                                style: const TextStyle(
                                  color: Color(0xFF2D86FF),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (todayRoutines.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1F2E),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '루틴이 없습니다',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        ...List.generate(todayRoutines.length, (i) {
                          final routine = todayRoutines[i];
                          final isDone = _isRoutineCompletedToday(routine);
                          final subtitle = _routineSubtitle(routine);
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: i < todayRoutines.length - 1 ? 10 : 0,
                            ),
                            child: GestureDetector(
                              onTap: () => _toggleRoutine(i),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1F2E),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.06),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.repeat_rounded,
                                      size: 18,
                                      color: isDone
                                          ? Colors.white.withOpacity(0.3)
                                          : const Color(0xFF2D86FF).withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      height: 26,
                                      width: 26,
                                      decoration: BoxDecoration(
                                        color: isDone
                                            ? const Color(0xFF2D86FF)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDone
                                              ? Colors.transparent
                                              : Colors.white.withOpacity(0.18),
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
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              decoration: isDone
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: isDone
                                                  ? Colors.white.withOpacity(0.45)
                                                  : Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            subtitle,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDone
                                                  ? Colors.white.withOpacity(0.3)
                                                  : Colors.white.withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // 할 일
              Builder(
                builder: (context) {
                  final todayTodos = _getTodayTodos();
                  final doneCount = todayTodos
                      .where((t) => t['done'] == true)
                      .length;
                  return Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.task_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "할 일",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          if (todayTodos.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F2538),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                              child: Text(
                                '$doneCount/${todayTodos.length}',
                                style: const TextStyle(
                                  color: Color(0xFF2D86FF),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (todayTodos.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1F2E),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '할 일이 없습니다',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        ...List.generate(todayTodos.length, (i) {
                          final todo = todayTodos[i];
                          final isDone = todo['done'] == true;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: i < todayTodos.length - 1 ? 10 : 0,
                            ),
                            child: GestureDetector(
                              onTap: () => _toggleTodo(i),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  14,
                                  12,
                                  14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F1F2E),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.06),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 26,
                                      width: 26,
                                      decoration: BoxDecoration(
                                        color: isDone
                                            ? const Color(0xFF2D86FF)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDone
                                              ? Colors.transparent
                                              : Colors.white.withOpacity(0.18),
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
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              decoration: isDone
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: isDone
                                                  ? Colors.white.withOpacity(0.45)
                                                  : Colors.white,
                                            ),
                                          ),
                                          if (todo['time'] != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time_rounded,
                                                  size: 13,
                                                  color: isDone
                                                      ? Colors.white.withOpacity(0.3)
                                                      : const Color(0xFF2D86FF).withOpacity(0.7),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  todo['time'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDone
                                                        ? Colors.white.withOpacity(0.3)
                                                        : const Color(0xFF2D86FF).withOpacity(0.7),
                                                  ),
                                                ),
                                                if (todo['notifyBefore'] != null) ...[
                                                  const SizedBox(width: 6),
                                                  Icon(
                                                    Icons.notifications_active_outlined,
                                                    size: 13,
                                                    color: isDone
                                                        ? Colors.white.withOpacity(0.3)
                                                        : Colors.white.withOpacity(0.4),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    (todo['notifyBefore'] as int) >= 60
                                                        ? '${(todo['notifyBefore'] as int) ~/ 60}시간 전'
                                                        : '${todo['notifyBefore']}분 전',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDone
                                                          ? Colors.white.withOpacity(0.3)
                                                          : Colors.white.withOpacity(0.4),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
              const SizedBox(height: 60),

              //
              // 나의 목표 상황
              Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    '분석',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2538),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: const Text(
                      '준비중...',
                      style: TextStyle(
                        color: Color(0xFF2D86FF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      '자세히',
                      style: TextStyle(
                        color: Color(0xFF2D86FF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 목표 카드 상황
              Row(
                children: [
                  Expanded(
                    child: Container(
                      // height: 140,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Color(0xFF0F1F2E),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                SizedBox(height: 10),
                                SizedBox(
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
                                            Colors.white.withOpacity(0.10),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 64,
                                        width: 64,
                                        child: CircularProgressIndicator(
                                          value: 0.45,
                                          strokeWidth: 7,
                                          valueColor: AlwaysStoppedAnimation(
                                            Color(0xFF22C55E),
                                          ),
                                          backgroundColor: Colors.transparent,
                                        ),
                                      ),
                                      Text(
                                        "45%",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "진행도",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "24/28",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
