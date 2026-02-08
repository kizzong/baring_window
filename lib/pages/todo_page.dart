import 'dart:convert';

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  String _dayKey(DateTime day) {
    return DateFormat('yyyy-MM-dd').format(day);
  }

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

  void _addTodo(String title) {
    final key = _dayKey(_selectedDay);
    _todos.putIfAbsent(key, () => []);
    _todos[key]!.add({'title': title, 'done': false});
    _saveTodos();
    setState(() {});
  }

  void _toggleTodo(int index) {
    final key = _dayKey(_selectedDay);
    if (_todos[key] != null && index < _todos[key]!.length) {
      _todos[key]![index]['done'] = !_todos[key]![index]['done'];
      _saveTodos();
      setState(() {});
    }
  }

  void _deleteTodo(int index) {
    final key = _dayKey(_selectedDay);
    if (_todos[key] != null && index < _todos[key]!.length) {
      final removed = _todos[key]!.removeAt(index);
      if (_todos[key]!.isEmpty) {
        _todos.remove(key);
      }
      _saveTodos();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${removed['title']}" 삭제됨',
            style: const TextStyle(fontWeight: FontWeight.w600),
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
            },
          ),
        ),
      );
    }
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    showDialog(
      context: context,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 100), () {
          focusNode.requestFocus();
        });
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
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            maxLength: 20,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '할 일을 입력하세요',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              counterStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2D86FF)),
              ),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _addTodo(value.trim());
                Navigator.pop(ctx);
              }
            },
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
                if (controller.text.trim().isNotEmpty) {
                  _addTodo(controller.text.trim());
                  Navigator.pop(ctx);
                }
              },
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
  }

  @override
  Widget build(BuildContext context) {
    final todosForDay = _getTodosForDay(_selectedDay);
    final selectedKey = _dayKey(_selectedDay);
    final isToday = isSameDay(_selectedDay, DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF0B1623),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1623),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          '할 일',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
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
            eventLoader: (day) => _getTodosForDay(day),
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
              markerDecoration: const BoxDecoration(
                color: Color(0xFF2D86FF),
                shape: BoxShape.circle,
              ),
              markerSize: 6,
              markersMaxCount: 4,
              markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
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

          // Selected day header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  isToday
                      ? '오늘의 할 일'
                      : '${_selectedDay.month}월 ${_selectedDay.day}일의 할 일',
                  style: const TextStyle(
                    fontSize: 18,
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

          // Todo list
          Expanded(
            child: todosForDay.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Colors.white.withOpacity(0.15),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '할 일이 없습니다',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: todosForDay.length,
                    itemBuilder: (context, index) {
                      final todo = todosForDay[index];
                      final isDone = todo['done'] == true;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: ValueKey('$selectedKey-$index-${todo['title']}'),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteTodo(index),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
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
                                InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _toggleTodo(index),
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
                                  child: Text(
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
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF2D86FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
