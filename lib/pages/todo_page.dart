import 'dart:convert';

import 'package:baring_windows/services/notification_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final Box _box = Hive.box('baring');
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<String, List<Map<String, dynamic>>> _todos = {};
  List<Map<String, dynamic>> _routines = [];

  static const _dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _loadRoutines();
  }

  String _dayKey(DateTime day) {
    return DateFormat('yyyy-MM-dd').format(day);
  }

  // ── Todo 데이터 관리 ──

  void _loadTodos() {
    final raw = _box.get('todos');
    if (raw != null) {
      final Map decoded = raw is String ? jsonDecode(raw) : Map.from(raw);
      _todos = decoded.map((key, value) {
        final list = (value as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        return MapEntry(key.toString(), list);
      });
    }
  }

  void _saveTodos() {
    _box.put(
      'todos',
      _todos.map((key, value) {
        return MapEntry(
          key,
          value.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
      }),
    );
  }

  List<Map<String, dynamic>> _getTodosForDay(DateTime day) {
    return _todos[_dayKey(day)] ?? [];
  }

  void _addTodo(String title, {String? time, int? notifyBefore}) {
    final key = _dayKey(_selectedDay);
    _todos.putIfAbsent(key, () => []);
    final todo = <String, dynamic>{'title': title, 'done': false};
    if (time != null) todo['time'] = time;
    if (notifyBefore != null) todo['notifyBefore'] = notifyBefore;
    _todos[key]!.add(todo);
    _saveTodos();
    setState(() {});

    // 알림 스케줄
    if (time != null && notifyBefore != null) {
      final index = _todos[key]!.length - 1;
      _scheduleNotificationForTodo(key, index, todo);
    }
  }

  void _editTodo(int index, String title, {String? time, int? notifyBefore}) {
    final key = _dayKey(_selectedDay);
    if (_todos[key] == null || index >= _todos[key]!.length) return;

    // 기존 알림 취소
    final old = _todos[key]![index];
    if (old['time'] != null && old['notifyBefore'] != null) {
      _cancelNotificationForTodo(key, index);
    }

    // 데이터 업데이트
    _todos[key]![index]['title'] = title;
    _todos[key]![index]['time'] = time;
    _todos[key]![index]['notifyBefore'] = notifyBefore;

    _saveTodos();
    setState(() {});

    // 새 알림 스케줄
    if (time != null && notifyBefore != null) {
      _scheduleNotificationForTodo(key, index, _todos[key]![index]);
    }
  }

  void _scheduleNotificationForTodo(
      String key, int index, Map<String, dynamic> todo) {
    final time = todo['time'] as String?;
    final notifyBefore = todo['notifyBefore'] as int?;
    if (time == null || notifyBefore == null) return;

    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final date = DateTime.parse(key);
    final scheduledTime = DateTime(date.year, date.month, date.day, hour, minute)
        .subtract(Duration(minutes: notifyBefore));

    final id = NotificationService.generateId(key, index);
    NotificationService.scheduleNotification(
      id: id,
      title: todo['title'] ?? '',
      time: time,
      notifyBefore: notifyBefore,
      scheduledTime: scheduledTime,
    );
  }

  void _cancelNotificationForTodo(String key, int index) {
    final id = NotificationService.generateId(key, index);
    NotificationService.cancelNotification(id);
  }

  void _toggleTodo(int index) {
    final key = _dayKey(_selectedDay);
    if (_todos[key] == null || index >= _todos[key]!.length) return;

    final todo = _todos[key]![index];
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
                _todos[key]![index]['done'] = true;
                _cancelNotificationForTodo(key, index);
                _saveTodos();
                setState(() {});
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
      _todos[key]![index]['done'] = false;
      _scheduleNotificationForTodo(key, index, _todos[key]![index]);
      _saveTodos();
      setState(() {});
      return;
    }

    // 알림 없는 할 일 → 기존 동작
    _todos[key]![index]['done'] = !isDone;
    _saveTodos();
    setState(() {});
  }

  void _deleteTodo(int index) {
    final key = _dayKey(_selectedDay);
    if (_todos[key] != null && index < _todos[key]!.length) {
      final removed = _todos[key]!.removeAt(index);

      // 알림 취소
      if (removed['time'] != null && removed['notifyBefore'] != null) {
        _cancelNotificationForTodo(key, index);
      }

      if (_todos[key]!.isEmpty) {
        _todos.remove(key);
      }
      _saveTodos();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${removed['title']}" 삭제됨',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white60,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFF1A2332),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: '되돌리기',
            textColor: const Color(0xFF2D86FF),
            onPressed: () {
              final key = _dayKey(_selectedDay);
              _todos.putIfAbsent(key, () => []);
              _todos[key]!.insert(index, removed);
              _saveTodos();
              setState(() {});

              // 되돌리기 시 알림 재스케줄
              if (removed['time'] != null && removed['notifyBefore'] != null) {
                _scheduleNotificationForTodo(key, index, removed);
              }
            },
          ),
        ),
      );
    }
  }

  void _reorderTodo(int oldIndex, int newIndex) {
    final key = _dayKey(_selectedDay);
    if (_todos[key] == null) return;
    if (newIndex > oldIndex) newIndex--;
    final item = _todos[key]!.removeAt(oldIndex);
    _todos[key]!.insert(newIndex, item);
    _saveTodos();
    setState(() {});
  }

  // ── 루틴 데이터 관리 ──

  void _loadRoutines() {
    final raw = _box.get('routines');
    if (raw != null) {
      _routines = (raw as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }

  void _saveRoutines() {
    _box.put(
      'routines',
      _routines.map((e) {
        final copy = Map<String, dynamic>.from(e);
        // completions를 Map으로 유지
        if (copy['completions'] != null) {
          copy['completions'] = Map<String, dynamic>.from(copy['completions']);
        }
        // days를 List로 유지
        if (copy['days'] != null) {
          copy['days'] = List<int>.from(copy['days']);
        }
        return copy;
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getRoutinesForDay(DateTime day) {
    final weekday = day.weekday; // 1=월 ~ 7=일
    return _routines.where((r) {
      if (r['type'] == 'daily') return true;
      if (r['type'] == 'weekly') {
        final days = List<int>.from(r['days'] ?? []);
        return days.contains(weekday);
      }
      return false;
    }).toList();
  }

  bool _isRoutineCompletedForDay(Map<String, dynamic> routine, DateTime day) {
    final completions = Map<String, dynamic>.from(routine['completions'] ?? {});
    return completions[_dayKey(day)] == true;
  }

  void _addRoutine(String title, {
    required String type,
    List<int>? days,
    String? time,
    int? notifyBefore,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final routine = <String, dynamic>{
      'id': id,
      'title': title,
      'type': type,
      'completions': <String, dynamic>{},
    };
    if (type == 'weekly' && days != null) routine['days'] = days;
    if (time != null) routine['time'] = time;
    if (notifyBefore != null) routine['notifyBefore'] = notifyBefore;
    _routines.add(routine);
    _saveRoutines();
    setState(() {});

    // 알림 스케줄
    if (time != null && notifyBefore != null) {
      _scheduleRoutineNotification(routine);
    }
  }

  void _editRoutine(int routineIndex, String title, {
    required String type,
    List<int>? days,
    String? time,
    int? notifyBefore,
  }) {
    final routinesForDay = _getRoutinesForDay(_selectedDay);
    if (routineIndex >= routinesForDay.length) return;

    final routine = routinesForDay[routineIndex];
    final globalIndex = _routines.indexWhere((r) => r['id'] == routine['id']);
    if (globalIndex == -1) return;

    // 기존 알림 취소
    if (_routines[globalIndex]['time'] != null &&
        _routines[globalIndex]['notifyBefore'] != null) {
      _cancelRoutineNotification(_routines[globalIndex]);
    }

    // 데이터 업데이트
    _routines[globalIndex]['title'] = title;
    _routines[globalIndex]['type'] = type;
    if (type == 'weekly' && days != null) {
      _routines[globalIndex]['days'] = days;
    } else {
      _routines[globalIndex].remove('days');
    }
    _routines[globalIndex]['time'] = time;
    _routines[globalIndex]['notifyBefore'] = notifyBefore;

    _saveRoutines();
    setState(() {});

    // 새 알림 스케줄
    if (time != null && notifyBefore != null) {
      _scheduleRoutineNotification(_routines[globalIndex]);
    }
  }

  void _toggleRoutine(int routineIndex) {
    final routinesForDay = _getRoutinesForDay(_selectedDay);
    if (routineIndex >= routinesForDay.length) return;

    final routine = routinesForDay[routineIndex];
    final globalIndex = _routines.indexWhere((r) => r['id'] == routine['id']);
    if (globalIndex == -1) return;

    final key = _dayKey(_selectedDay);
    final completions = Map<String, dynamic>.from(
        _routines[globalIndex]['completions'] ?? {});
    completions[key] = !(completions[key] == true);
    _routines[globalIndex]['completions'] = completions;
    _saveRoutines();
    setState(() {});
  }

  void _deleteRoutine(int routineIndex) {
    final routinesForDay = _getRoutinesForDay(_selectedDay);
    if (routineIndex >= routinesForDay.length) return;

    final routine = routinesForDay[routineIndex];
    final globalIndex = _routines.indexWhere((r) => r['id'] == routine['id']);
    if (globalIndex == -1) return;

    final removed = _routines.removeAt(globalIndex);

    // 알림 취소
    if (removed['time'] != null && removed['notifyBefore'] != null) {
      _cancelRoutineNotification(removed);
    }

    _saveRoutines();
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${removed['title']}" 루틴 삭제됨',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white60,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF1A2332),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: '되돌리기',
          textColor: const Color(0xFF2D86FF),
          onPressed: () {
            _routines.insert(globalIndex, removed);
            _saveRoutines();
            setState(() {});

            if (removed['time'] != null && removed['notifyBefore'] != null) {
              _scheduleRoutineNotification(removed);
            }
          },
        ),
      ),
    );
  }

  void _scheduleRoutineNotification(Map<String, dynamic> routine) {
    final time = routine['time'] as String?;
    final notifyBefore = routine['notifyBefore'] as int?;
    final id = routine['id'] as String;
    if (time == null || notifyBefore == null) return;

    final type = routine['type'] as String;

    if (type == 'daily') {
      final notifId = NotificationService.generateRoutineId(id);
      NotificationService.scheduleRoutineNotification(
        id: notifId,
        title: routine['title'] ?? '',
        time: time,
        notifyBefore: notifyBefore,
        type: 'daily',
      );
    } else if (type == 'weekly') {
      final days = List<int>.from(routine['days'] ?? []);
      for (final weekday in days) {
        final notifId = NotificationService.generateRoutineId('${id}_$weekday');
        NotificationService.scheduleRoutineNotification(
          id: notifId,
          title: routine['title'] ?? '',
          time: time,
          notifyBefore: notifyBefore,
          type: 'weekly',
          weekday: weekday,
        );
      }
    }
  }

  void _cancelRoutineNotification(Map<String, dynamic> routine) {
    final id = routine['id'] as String;
    final type = routine['type'] as String;

    if (type == 'daily') {
      final notifId = NotificationService.generateRoutineId(id);
      NotificationService.cancelRoutineNotification(notifId);
    } else if (type == 'weekly') {
      final days = List<int>.from(routine['days'] ?? []);
      for (final weekday in days) {
        final notifId = NotificationService.generateRoutineId('${id}_$weekday');
        NotificationService.cancelRoutineNotification(notifId);
      }
    }
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
                  timeStr =
                      '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                }
                _addTodo(
                  controller.text.trim(),
                  time: timeStr,
                  notifyBefore: selectedTime != null ? selectedNotifyBefore : null,
                );
                Navigator.pop(ctx);
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1A2332),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '할 일 추가',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '할 일을 입력하세요',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.4)),
                        counterStyle:
                            TextStyle(color: Colors.white.withOpacity(0.4)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.15)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF2D86FF)),
                        ),
                      ),
                      onEditingComplete: () => focusNode.unfocus(),
                    ),
                    const SizedBox(height: 16),

                    // 시간 선택
                    _buildTimePickerButton(
                      selectedTime: selectedTime,
                      onTimeSelected: (time) {
                        setDialogState(() => selectedTime = time);
                      },
                      onTimeClear: () {
                        setDialogState(() {
                          selectedTime = null;
                          selectedNotifyBefore = null;
                        });
                      },
                    ),

                    // 알림 선택 (시간이 설정된 경우에만)
                    if (selectedTime != null) ...[
                      const SizedBox(height: 12),
                      _buildNotifyOptions(
                        notifyOptions: notifyOptions,
                        selectedNotifyBefore: selectedNotifyBefore,
                        onSelected: (value) {
                          setDialogState(() => selectedNotifyBefore = value);
                        },
                      ),
                    ],
                  ],
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
                  onPressed: submit,
                  child: const Text(
                    '추가',
                    style: TextStyle(
                      color: Color(0xFF2D86FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddRoutineDialog() {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    String routineType = 'daily';
    List<int> selectedDays = [];
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
                timeStr =
                    '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
              }
              _addRoutine(
                title,
                type: routineType,
                days: routineType == 'weekly' ? (List<int>.from(selectedDays)..sort()) : null,
                time: timeStr,
                notifyBefore: selectedTime != null ? selectedNotifyBefore : null,
              );
              Navigator.pop(ctx);
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1A2332),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '루틴 추가',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 루틴 이름 입력
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      maxLength: 20,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '루틴 이름을 입력하세요',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.4)),
                        counterStyle:
                            TextStyle(color: Colors.white.withOpacity(0.4)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.15)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF2D86FF)),
                        ),
                      ),
                      onEditingComplete: () => focusNode.unfocus(),
                    ),
                    const SizedBox(height: 16),

                    // 반복 유형 선택
                    Text(
                      '반복',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                routineType = 'daily';
                                selectedDays = [];
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: routineType == 'daily'
                                    ? const Color(0xFF2D86FF).withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: routineType == 'daily'
                                      ? const Color(0xFF2D86FF)
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '매일',
                                  style: TextStyle(
                                    color: routineType == 'daily'
                                        ? const Color(0xFF2D86FF)
                                        : Colors.white.withOpacity(0.6),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() => routineType = 'weekly');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: routineType == 'weekly'
                                    ? const Color(0xFF2D86FF).withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: routineType == 'weekly'
                                      ? const Color(0xFF2D86FF)
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '특정 요일',
                                  style: TextStyle(
                                    color: routineType == 'weekly'
                                        ? const Color(0xFF2D86FF)
                                        : Colors.white.withOpacity(0.6),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 요일 선택 (특정 요일인 경우)
                    if (routineType == 'weekly') ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (i) {
                          final day = i + 1; // 1=월 ~ 7=일
                          final isSelected = selectedDays.contains(day);
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                if (isSelected) {
                                  selectedDays.remove(day);
                                } else {
                                  selectedDays.add(day);
                                }
                              });
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2D86FF)
                                    : Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _dayNames[i],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // 시간 선택
                    _buildTimePickerButton(
                      selectedTime: selectedTime,
                      onTimeSelected: (time) {
                        setDialogState(() => selectedTime = time);
                      },
                      onTimeClear: () {
                        setDialogState(() {
                          selectedTime = null;
                          selectedNotifyBefore = null;
                        });
                      },
                    ),

                    // 알림 선택 (시간이 설정된 경우에만)
                    if (selectedTime != null) ...[
                      const SizedBox(height: 12),
                      _buildNotifyOptions(
                        notifyOptions: notifyOptions,
                        selectedNotifyBefore: selectedNotifyBefore,
                        onSelected: (value) {
                          setDialogState(() => selectedNotifyBefore = value);
                        },
                      ),
                    ],
                  ],
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
                  onPressed: submit,
                  child: const Text(
                    '추가',
                    style: TextStyle(
                      color: Color(0xFF2D86FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTodoDialog(int index) {
    final key = _dayKey(_selectedDay);
    if (_todos[key] == null || index >= _todos[key]!.length) return;
    final todo = _todos[key]![index];

    final controller = TextEditingController(text: todo['title'] ?? '');
    final focusNode = FocusNode();
    TimeOfDay? selectedTime;
    if (todo['time'] != null) {
      final parts = (todo['time'] as String).split(':');
      selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
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
                  timeStr =
                      '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                }
                _editTodo(
                  index,
                  controller.text.trim(),
                  time: timeStr,
                  notifyBefore: selectedTime != null ? selectedNotifyBefore : null,
                );
                Navigator.pop(ctx);
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1A2332),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '할 일 수정',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '할 일을 입력하세요',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.4)),
                        counterStyle:
                            TextStyle(color: Colors.white.withOpacity(0.4)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.15)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF2D86FF)),
                        ),
                      ),
                      onEditingComplete: () => focusNode.unfocus(),
                    ),
                    const SizedBox(height: 16),
                    _buildTimePickerButton(
                      selectedTime: selectedTime,
                      onTimeSelected: (time) {
                        setDialogState(() => selectedTime = time);
                      },
                      onTimeClear: () {
                        setDialogState(() {
                          selectedTime = null;
                          selectedNotifyBefore = null;
                        });
                      },
                    ),
                    if (selectedTime != null) ...[
                      const SizedBox(height: 12),
                      _buildNotifyOptions(
                        notifyOptions: notifyOptions,
                        selectedNotifyBefore: selectedNotifyBefore,
                        onSelected: (value) {
                          setDialogState(() => selectedNotifyBefore = value);
                        },
                      ),
                    ],
                  ],
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
                  onPressed: submit,
                  child: const Text(
                    '수정',
                    style: TextStyle(
                      color: Color(0xFF2D86FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditRoutineDialog(int routineIndex) {
    final routinesForDay = _getRoutinesForDay(_selectedDay);
    if (routineIndex >= routinesForDay.length) return;
    final routine = routinesForDay[routineIndex];

    final controller = TextEditingController(text: routine['title'] ?? '');
    final focusNode = FocusNode();
    String routineType = routine['type'] as String? ?? 'daily';
    List<int> selectedDays = List<int>.from(routine['days'] ?? []);
    TimeOfDay? selectedTime;
    if (routine['time'] != null) {
      final parts = (routine['time'] as String).split(':');
      selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
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
                timeStr =
                    '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
              }
              _editRoutine(
                routineIndex,
                title,
                type: routineType,
                days: routineType == 'weekly' ? (List<int>.from(selectedDays)..sort()) : null,
                time: timeStr,
                notifyBefore: selectedTime != null ? selectedNotifyBefore : null,
              );
              Navigator.pop(ctx);
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1A2332),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                '루틴 수정',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '루틴 이름을 입력하세요',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.4)),
                        counterStyle:
                            TextStyle(color: Colors.white.withOpacity(0.4)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.15)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF2D86FF)),
                        ),
                      ),
                      onEditingComplete: () => focusNode.unfocus(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '반복',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                routineType = 'daily';
                                selectedDays = [];
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: routineType == 'daily'
                                    ? const Color(0xFF2D86FF).withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: routineType == 'daily'
                                      ? const Color(0xFF2D86FF)
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '매일',
                                  style: TextStyle(
                                    color: routineType == 'daily'
                                        ? const Color(0xFF2D86FF)
                                        : Colors.white.withOpacity(0.6),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() => routineType = 'weekly');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: routineType == 'weekly'
                                    ? const Color(0xFF2D86FF).withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: routineType == 'weekly'
                                      ? const Color(0xFF2D86FF)
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '특정 요일',
                                  style: TextStyle(
                                    color: routineType == 'weekly'
                                        ? const Color(0xFF2D86FF)
                                        : Colors.white.withOpacity(0.6),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
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
                            onTap: () {
                              setDialogState(() {
                                if (isSelected) {
                                  selectedDays.remove(day);
                                } else {
                                  selectedDays.add(day);
                                }
                              });
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2D86FF)
                                    : Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _dayNames[i],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildTimePickerButton(
                      selectedTime: selectedTime,
                      onTimeSelected: (time) {
                        setDialogState(() => selectedTime = time);
                      },
                      onTimeClear: () {
                        setDialogState(() {
                          selectedTime = null;
                          selectedNotifyBefore = null;
                        });
                      },
                    ),
                    if (selectedTime != null) ...[
                      const SizedBox(height: 12),
                      _buildNotifyOptions(
                        notifyOptions: notifyOptions,
                        selectedNotifyBefore: selectedNotifyBefore,
                        onSelected: (value) {
                          setDialogState(() => selectedNotifyBefore = value);
                        },
                      ),
                    ],
                  ],
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
                  onPressed: submit,
                  child: const Text(
                    '수정',
                    style: TextStyle(
                      color: Color(0xFF2D86FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── 공통 위젯 빌더 ──

  Widget _buildTimePickerButton({
    required TimeOfDay? selectedTime,
    required void Function(TimeOfDay) onTimeSelected,
    required VoidCallback onTimeClear,
  }) {
    return GestureDetector(
      onTap: () async {
        DateTime tempTime = DateTime(
          2000, 1, 1,
          selectedTime?.hour ?? TimeOfDay.now().hour,
          selectedTime?.minute ?? TimeOfDay.now().minute,
        );
        await showCupertinoModalPopup(
          context: context,
          builder: (pickerCtx) {
            return Container(
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0xFF1A2332),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            '취소',
                            style: TextStyle(
                              color: Colors.white
                                  .withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                          onPressed: () =>
                              Navigator.pop(pickerCtx),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Text(
                            '확인',
                            style: TextStyle(
                              color: Color(0xFF2D86FF),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: () {
                            onTimeSelected(TimeOfDay(
                              hour: tempTime.hour,
                              minute: tempTime.minute,
                            ));
                            Navigator.pop(pickerCtx);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Localizations(
                      locale: const Locale('ko', 'KR'),
                      delegates: const [
                        GlobalCupertinoLocalizations.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                      ],
                      child: CupertinoTheme(
                        data: const CupertinoThemeData(
                          brightness: Brightness.dark,
                          textTheme: CupertinoTextThemeData(
                            dateTimePickerTextStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          initialDateTime: tempTime,
                          use24hFormat: false,
                          onDateTimeChanged: (dt) {
                            tempTime = dt;
                          },
                        ),
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
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedTime != null
                ? const Color(0xFF2D86FF).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 20,
              color: selectedTime != null
                  ? const Color(0xFF2D86FF)
                  : Colors.white.withOpacity(0.4),
            ),
            const SizedBox(width: 10),
            Text(
              selectedTime != null
                  ? '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'
                  : '시간 선택 (선택사항)',
              style: TextStyle(
                color: selectedTime != null
                    ? Colors.white
                    : Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            if (selectedTime != null)
              GestureDetector(
                onTap: onTimeClear,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알림',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: notifyOptions.map((option) {
            final value = option['value'] as int?;
            final isSelected = selectedNotifyBefore == value;
            return GestureDetector(
              onTap: () => onSelected(value),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2D86FF).withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2D86FF)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  option['label'] as String,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF2D86FF)
                        : Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
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

    if (time != null) {
      parts.add(time);
    }

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final todosForDay = _getTodosForDay(_selectedDay);
    final routinesForDay = _getRoutinesForDay(_selectedDay);
    final selectedKey = _dayKey(_selectedDay);

    final routineDoneCount = routinesForDay
        .where((r) => _isRoutineCompletedForDay(r, _selectedDay))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1623),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1623),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          '할 일 관리',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          GestureDetector(
            onTap: _showAddRoutineDialog,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2D86FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2D86FF).withOpacity(0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    color: Color(0xFF2D86FF),
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '루틴 추가',
                    style: TextStyle(
                      color: Color(0xFF2D86FF),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
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
            eventLoader: (day) {
              final todos = _getTodosForDay(day);
              final routines = _getRoutinesForDay(day);
              final count = todos.length + routines.length;
              return List.generate(count.clamp(0, 4), (_) => '');
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final hasTodos = _getTodosForDay(day).isNotEmpty;
                final hasRoutines = _getRoutinesForDay(day).isNotEmpty;
                if (!hasTodos && !hasRoutines) return null;

                final dots = <Widget>[];
                if (hasRoutines) {
                  dots.add(Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ));
                }
                if (hasTodos) {
                  final todoCount = _getTodosForDay(day).length.clamp(1, 4);
                  for (var i = 0; i < todoCount; i++) {
                    dots.add(Container(
                      width: 6, height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D86FF),
                        shape: BoxShape.circle,
                      ),
                    ));
                  }
                }
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: dots,
                  ),
                );
              },
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              weekendTextStyle: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF2D86FF).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF2D86FF),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              markersMaxCount: 0,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              leftChevronIcon: const Icon(
                Icons.chevron_left,
                color: Colors.white,
              ),
              rightChevronIcon: const Icon(
                Icons.chevron_right,
                color: Colors.white,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              weekendStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 루틴 + 할일 리스트
          Expanded(
            child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // ── 날짜 헤더 ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              DateFormat('M월 d일 (E)', 'ko').format(_selectedDay),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── 루틴 섹션 ──
                      if (routinesForDay.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.repeat_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '루틴',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D86FF).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$routineDoneCount/${routinesForDay.length}',
                                  style: const TextStyle(
                                    color: Color(0xFF2D86FF),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...List.generate(routinesForDay.length, (i) {
                            final routine = routinesForDay[i];
                            final isDone = _isRoutineCompletedForDay(routine, _selectedDay);
                            final subtitle = _routineSubtitle(routine);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GestureDetector(
                                  onTap: () => _showEditRoutineDialog(i),
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF121E2B),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.07),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // 반복 아이콘 + 체크박스
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
                                        IconButton(
                                          onPressed: () => _deleteRoutine(i),
                                          icon: Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Colors.white.withOpacity(0.3),
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
                          }),
                        const SizedBox(height: 8),
                      ],

                      // ── 할일 섹션 ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.task_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '할 일',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (todosForDay.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D86FF).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${todosForDay.where((t) => t['done'] == true).length}/${todosForDay.length}',
                                  style: const TextStyle(
                                    color: Color(0xFF2D86FF),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            IconButton(
                              onPressed: _showAddDialog,
                              icon: const Icon(
                                Icons.add,
                                color: Color(0xFF2D86FF),
                                size: 25,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (todosForDay.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121E2B),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.07),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '할 일이 없습니다',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        ...List.generate(todosForDay.length, (index) {
                          final todo = todosForDay[index];
                          final isDone = todo['done'] == true;
                          final timeStr = todo['time'] as String?;
                          final notifyBefore = todo['notifyBefore'] as int?;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                                onTap: () => _showEditTodoDialog(index),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF121E2B),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.07),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _toggleTodo(index),
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
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
                                                    ? Colors.white.withOpacity(0.45)
                                                    : Colors.white,
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
                                                        ? Colors.white.withOpacity(0.3)
                                                        : const Color(0xFF2D86FF).withOpacity(0.7),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    timeStr,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: isDone
                                                          ? Colors.white.withOpacity(0.3)
                                                          : const Color(0xFF2D86FF).withOpacity(0.7),
                                                    ),
                                                  ),
                                                  if (notifyBefore != null) ...[
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
                                                      notifyBefore >= 60
                                                          ? '${notifyBefore ~/ 60}시간 전'
                                                          : '$notifyBefore분 전',
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
                                      IconButton(
                                        onPressed: () => _deleteTodo(index),
                                        icon: Icon(
                                          Icons.close,
                                          size: 18,
                                          color: Colors.white.withOpacity(0.3),
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
                        }),

                      const SizedBox(height: 20),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
