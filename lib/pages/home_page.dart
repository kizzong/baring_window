import 'dart:io';

import 'package:baring_windows/pages/dday_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Box baringBox = Hive.box("baring");

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

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  List<Map<String, dynamic>> _getTodayTodos() {
    final raw = baringBox.get('todos');
    if (raw == null) return [];
    final Map data = Map.from(raw);
    final list = data[_todayKey];
    if (list == null) return [];
    return (list as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void _toggleTodo(int index) {
    final raw = baringBox.get('todos');
    if (raw == null) return;
    final Map data = Map.from(raw);
    final list = data[_todayKey];
    if (list == null || index >= (list as List).length) return;
    final todos = list.map((e) => Map<String, dynamic>.from(e)).toList();
    todos[index]['done'] = !(todos[index]['done'] as bool);
    data[_todayKey] = todos;
    baringBox.put('todos', data);
    setState(() {});
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
              const SizedBox(height: 32),

              // 오늘의 할 일
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
                          Icon(
                            Icons.task_alt_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "오늘의 할 일",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (todayTodos.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
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
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 15),
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
                              '오늘의 할 일이 없습니다',
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
