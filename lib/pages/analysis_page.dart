import 'package:baring_windows/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> with SingleTickerProviderStateMixin {
  Box baringBox = Hive.box("baring");

  late final AnimationController _animController;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── 데이터 로드 ──

  Map<String, List<Map<String, dynamic>>> _getAllTodos() {
    final raw = baringBox.get('todos');
    if (raw == null) return {};
    final map = Map<String, dynamic>.from(raw);
    return map.map((key, value) {
      final list = (value as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return MapEntry(key, list);
    });
  }

  List<Map<String, dynamic>> _getAllRoutines() {
    final raw = baringBox.get('routines');
    if (raw == null) return [];
    return (raw as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  // ── 주간/월간 범위 ──

  List<DateTime> _weekDays(DateTime anchor) {
    final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }


  // ── 일별 완료 수 / 전체 수 ──

  int _completedCountForDay(DateTime day, Map<String, List<Map<String, dynamic>>> todos, List<Map<String, dynamic>> routines) {
    final key = _dateKey(day);
    int count = 0;

    // 할일 완료 수
    final dayTodos = todos[key] ?? [];
    count += dayTodos.where((t) => t['done'] == true).length;

    // 루틴 완료 수
    final weekday = day.weekday;
    for (final r in routines) {
      final isActive = r['type'] == 'daily' ||
          (r['type'] == 'weekly' && (List<int>.from(r['days'] ?? [])).contains(weekday));
      if (!isActive) continue;
      final completions = Map<String, dynamic>.from(r['completions'] ?? {});
      if (completions[key] == true) count++;
    }
    return count;
  }

  int _totalCountForDay(DateTime day, Map<String, List<Map<String, dynamic>>> todos, List<Map<String, dynamic>> routines) {
    final key = _dateKey(day);
    int count = 0;

    count += (todos[key] ?? []).length;

    final weekday = day.weekday;
    for (final r in routines) {
      final isActive = r['type'] == 'daily' ||
          (r['type'] == 'weekly' && (List<int>.from(r['days'] ?? [])).contains(weekday));
      if (isActive) count++;
    }
    return count;
  }


  // ── 주간/월간 바 차트 데이터 ──

  List<_BarData> _weeklyBarData() {
    final todos = _getAllTodos();
    final routines = _getAllRoutines();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = _weekDays(today);
    const labels = ['월', '화', '수', '목', '금', '토', '일'];

    return List.generate(7, (i) {
      final d = days[i];
      final completed = _completedCountForDay(d, todos, routines);
      final total = _totalCountForDay(d, todos, routines);
      return _BarData(
        label: labels[i],
        value: completed.toDouble(),
        maxValue: total.toDouble(),
        isToday: _dateKey(d) == _dateKey(today),
      );
    });
  }


  // ── 스트릭 계산 ──

  List<_StreakData> _streakData() {
    final routines = _getAllRoutines();
    if (routines.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return routines.map((r) {
      int current = 0;
      int max = 0;
      int streak = 0;

      // 최근 365일 체크
      for (int i = 0; i < 365; i++) {
        final d = today.subtract(Duration(days: i));
        final weekday = d.weekday;
        final isActive = r['type'] == 'daily' ||
            (r['type'] == 'weekly' && (List<int>.from(r['days'] ?? [])).contains(weekday));
        if (!isActive) continue;

        final completions = Map<String, dynamic>.from(r['completions'] ?? {});
        if (completions[_dateKey(d)] == true) {
          streak++;
          if (i == 0 || current > 0) current = streak;
          if (streak > max) max = streak;
        } else {
          if (i == 0) current = 0;
          streak = 0;
        }
      }

      return _StreakData(
        title: r['title'] ?? '',
        current: current,
        max: max,
      );
    }).toList()
      ..sort((a, b) => b.current.compareTo(a.current));
  }


  // ── 빌드 ──

  DateTime _selectedMonth = DateTime.now();
  int _monthSlideDirection = 1; // 1: 오른쪽→왼쪽(다음달), -1: 왼쪽→오른쪽(이전달)

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todos = _getAllTodos();
    final routines = _getAllRoutines();
    final todayTotal = _totalCountForDay(today, todos, routines);
    final hasData = todayTotal > 0 || routines.isNotEmpty;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        child: hasData
            ? AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  final av = _anim.value;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // 타이틀
                        Row(
                          children: [
                            Icon(Icons.bar_chart, color: c.textPrimary, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              '분석',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 1. 오늘의 현황
                        _buildTodayStatus(c),
                        const SizedBox(height: 24),

                        // 2. 루틴 연속 기록
                        _buildStreaks(c),
                        const SizedBox(height: 24),

                        // 3. 이번주 통계
                        _buildWeeklyStats(c, av),
                        const SizedBox(height: 24),

                        // 4. 월별 통계 (히트맵)
                        _buildMonthlyHeatmap(c),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              )
            : _buildEmptyState(c),
      ),
    );
  }

  // ── 빈 상태 ──

  Widget _buildEmptyState(AppColors c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: c.subtle.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            '아직 데이터가 없어요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '할일이나 루틴을 추가하면\n분석 결과를 볼 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }



  // ── 1. 오늘의 현황 ──

  Widget _buildTodayStatus(AppColors c) {
    final todos = _getAllTodos();
    final routines = _getAllRoutines();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayCompleted = _completedCountForDay(today, todos, routines);
    final todayTotal = _totalCountForDay(today, todos, routines);
    final todayRate = todayTotal > 0 ? todayCompleted / todayTotal : 0.0;

    // 할일만
    final key = _dateKey(today);
    final dayTodos = todos[key] ?? [];
    final todosCompleted = dayTodos.where((t) => t['done'] == true).length;
    final todosTotal = dayTodos.length;

    // 루틴만
    final routinesCompleted = todayCompleted - todosCompleted;
    final routinesTotal = todayTotal - todosTotal;

    Color rateColor;
    if (todayRate >= 0.8) {
      rateColor = const Color(0xFF22C55E);
    } else if (todayRate >= 0.5) {
      rateColor = const Color(0xFFFBBF24);
    } else if (todayRate > 0) {
      rateColor = const Color(0xFFF97316);
    } else {
      rateColor = c.subtle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, '오늘의 현황'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderColor),
          ),
          child: Column(
            children: [
              // 전체 완료율
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$todayCompleted',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: rateColor,
                    ),
                  ),
                  Text(
                    ' / $todayTotal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${(todayRate * 100).round()}%)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: rateColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 프로그레스바
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: todayRate,
                  minHeight: 8,
                  backgroundColor: c.textPrimary.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation(rateColor),
                ),
              ),
              const SizedBox(height: 12),
              // 할일 / 루틴 구분
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.scaffoldBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_box_outlined, size: 20, color: c.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '할일',
                              style: TextStyle(
                                fontSize: 13,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            '$todosCompleted/$todosTotal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.scaffoldBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.repeat, size: 20, color: c.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '루틴',
                              style: TextStyle(
                                fontSize: 13,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            '$routinesCompleted/$routinesTotal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
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
      ],
    );
  }

  // ── 3. 이번주 통계 ──

  Widget _buildWeeklyStats(AppColors c, double animValue) {
    final bars = _weeklyBarData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, '이번주 통계'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderColor),
          ),
          child: _BarChart(
            key: const ValueKey('weekly'),
            bars: bars,
            colors: c,
            animValue: animValue,
          ),
        ),
      ],
    );
  }


  // ── 4. 연속 기록 ──

  Widget _buildStreaks(AppColors c) {
    final streaks = _streakData();
    if (streaks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, '연속 기록'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderColor),
          ),
          child: Column(
            children: streaks.asMap().entries.map((entry) {
              final s = entry.value;
              final isLast = entry.key == streaks.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.local_fire_department,
                        size: 22,
                        color: s.current > 0 ? const Color(0xFFF97316) : c.subtle),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${s.current}일 연속',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: s.current > 0 ? const Color(0xFFF97316) : c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '최대 ${s.max}일',
                          style: TextStyle(
                            fontSize: 11,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── 4. 월별 통계 (히트맵) ──

  Widget _buildMonthlyHeatmap(AppColors c) {
    final todos = _getAllTodos();
    final routines = _getAllRoutines();

    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 월의 모든 날짜 데이터 생성
    final List<Map<String, dynamic>> dayData = [];
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final isFuture = date.isAfter(today);

      if (isFuture) {
        dayData.add({
          'day': day,
          'rate': 0.0,
          'completed': 0,
          'total': 0,
          'isFuture': true,
          'isToday': false,
        });
      } else {
        final completed = _completedCountForDay(date, todos, routines);
        final total = _totalCountForDay(date, todos, routines);
        final rate = total > 0 ? completed / total : 0.0;

        dayData.add({
          'day': day,
          'rate': rate,
          'completed': completed,
          'total': total,
          'isFuture': false,
          'isToday': _dateKey(date) == _dateKey(today),
        });
      }
    }

    // 월 통계
    int monthCompleted = 0;
    int monthTotal = 0;
    for (final d in dayData) {
      if (!d['isFuture']) {
        monthCompleted += d['completed'] as int;
        monthTotal += d['total'] as int;
      }
    }
    final monthRate = monthTotal > 0 ? (monthCompleted / monthTotal * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle(c, '월별 통계'),
            const Spacer(),
            // 월 선택 컨트롤
            GestureDetector(
              onTap: () {
                setState(() {
                  _monthSlideDirection = -1;
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.chipBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_left, size: 20, color: c.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_selectedMonth.year}년 ${_selectedMonth.month}월',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                if (next.isBefore(DateTime.now()) || next.year == now.year && next.month == now.month) {
                  setState(() {
                    _monthSlideDirection = 1;
                    _selectedMonth = next;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.chipBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right, size: 20, color: c.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final isNewChild = child.key == ValueKey('${_selectedMonth.year}-${_selectedMonth.month}');
            final offset = Tween<Offset>(
              begin: Offset(isNewChild ? _monthSlideDirection * 0.15 : -_monthSlideDirection * 0.15, 0),
              end: Offset.zero,
            ).animate(animation);
            return SlideTransition(
              position: offset,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Container(
            key: ValueKey('${_selectedMonth.year}-${_selectedMonth.month}'),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 월 요약
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.scaffoldBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$monthRate%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: monthRate >= 70
                                  ? const Color(0xFF22C55E)
                                  : monthRate >= 40
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '완료율',
                            style: TextStyle(fontSize: 12, color: c.textSecondary),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 40, color: c.borderColor),
                      Column(
                        children: [
                          Text(
                            '$monthCompleted',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '완료',
                            style: TextStyle(fontSize: 12, color: c.textSecondary),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 40, color: c.borderColor),
                      Column(
                        children: [
                          Text(
                            '$monthTotal',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '전체',
                            style: TextStyle(fontSize: 12, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 히트맵 그리드
                _buildHeatmapGrid(c, dayData),
                const SizedBox(height: 12),
                // 범례
                _buildHeatmapLegend(c),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapGrid(AppColors c, List<Map<String, dynamic>> dayData) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: dayData.map((d) {
        final day = d['day'] as int;
        final rate = d['rate'] as double;
        final isFuture = d['isFuture'] as bool;
        final isToday = d['isToday'] as bool;
        final total = d['total'] as int;

        Color cellColor;
        if (isFuture) {
          cellColor = c.subtle.withOpacity(0.1);
        } else if (total == 0) {
          cellColor = c.subtle.withOpacity(0.2);
        } else {
          // GitHub 스타일: 완료율에 따라 색상 진하기 조절
          final baseColor = const Color(0xFF22C55E);
          if (rate >= 0.9) {
            cellColor = baseColor;
          } else if (rate >= 0.7) {
            cellColor = baseColor.withOpacity(0.75);
          } else if (rate >= 0.5) {
            cellColor = baseColor.withOpacity(0.5);
          } else if (rate >= 0.3) {
            cellColor = baseColor.withOpacity(0.3);
          } else if (rate > 0) {
            cellColor = baseColor.withOpacity(0.15);
          } else {
            // 0% 완료 = 회색
            cellColor = c.subtle.withOpacity(0.35);
          }
        }

        return Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(6),
            border: isToday ? Border.all(color: c.primary, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: isFuture || total == 0
                  ? c.subtle
                  : rate > 0.3
                      ? Colors.white
                      : c.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeatmapLegend(AppColors c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('적음', style: TextStyle(fontSize: 10, color: c.textSecondary)),
        const SizedBox(width: 6),
        _heatmapLegendBox(c, const Color(0xFF22C55E).withOpacity(0.15)),
        const SizedBox(width: 3),
        _heatmapLegendBox(c, const Color(0xFF22C55E).withOpacity(0.3)),
        const SizedBox(width: 3),
        _heatmapLegendBox(c, const Color(0xFF22C55E).withOpacity(0.5)),
        const SizedBox(width: 3),
        _heatmapLegendBox(c, const Color(0xFF22C55E).withOpacity(0.75)),
        const SizedBox(width: 3),
        _heatmapLegendBox(c, const Color(0xFF22C55E)),
        const SizedBox(width: 6),
        Text('많음', style: TextStyle(fontSize: 10, color: c.textSecondary)),
      ],
    );
  }

  Widget _heatmapLegendBox(AppColors c, Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  // ── 공통 위젯 ──

  static const _helpTexts = {
    '오늘의 현황': '오늘 해야 할 할일과 루틴 중 몇 개를 완료했는지 보여줘요.\n\n'
        '큰 숫자는 완료한 개수, 아래는 전체 개수예요.\n\n'
        '예) 오늘 할일 3개 + 루틴 2개 = 총 5개\n'
        '그중 3개 완료 → "3 / 5" (60%)\n\n'
        '할일과 루틴은 각각 따로 표시돼요.',
    '연속 기록': '각 루틴의 연속 완료 기록을 보여줘요.\n\n'
        '현재 연속: 오늘부터 거슬러 올라가며 끊기지 않고 완료한 일수예요.\n\n'
        '최대 연속: 최근 1년 내 가장 긴 연속 완료 기록이에요.\n\n'
        '주간 루틴은 해당 요일만 카운트해요.\n\n'
        '🔥 아이콘은 현재 연속 중인 루틴을 나타내요.',
    '이번주 통계': '이번 주 월~일, 요일별 완료 수를 바 차트로 보여줘요.\n\n'
        '오늘은 파란색으로 강조돼요.\n\n'
        '예) 화요일에 할일 2개 + 루틴 1개 = 전체 3개\n'
        '그중 1개 완료 → 숫자 "1", 바가 1/3만큼 채워져요.\n\n'
        '회색 바 = 전체 수 (할일+루틴)\n'
        '파란 바 = 완료 수',
    '월별 통계': '선택한 달의 일별 완료 현황을 히트맵으로 보여줘요.\n\n'
        '각 칸은 하루를 나타내고, 색이 진할수록 완료율이 높아요.\n\n'
        '색상 기준:\n'
        '• 진한 초록 (90%+)\n'
        '• 중간 초록 (70%+)\n'
        '• 연한 초록 (50%+)\n'
        '• 아주 연한 초록 (30%+)\n'
        '• 거의 없음 (30% 미만)\n'
        '• 빨간색 (0% 완료)\n\n'
        '좌우 화살표로 월을 변경할 수 있어요.',
  };

  void _showHelpDialog(AppColors c, String title) {
    final description = _helpTexts[title] ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.help_outline, size: 22, color: c.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          description,
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
              '확인',
              style: TextStyle(
                color: c.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(AppColors c, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => _showHelpDialog(c, title),
          child: Icon(
            Icons.help_outline,
            size: 18,
            color: c.subtle,
          ),
        ),
      ],
    );
  }
}

// ── 커스텀 바 차트 위젯 ──

class _BarChart extends StatelessWidget {
  final List<_BarData> bars;
  final AppColors colors;
  final double animValue;

  const _BarChart({super.key, required this.bars, required this.colors, this.animValue = 1.0});

  @override
  Widget build(BuildContext context) {
    final maxVal = bars.fold<double>(0, (prev, b) => b.maxValue > prev ? b.maxValue : prev);
    if (maxVal == 0) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            '데이터가 없어요',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((b) {
          final totalHeight = maxVal > 0 ? (b.maxValue / maxVal) * 100 * animValue : 0.0;
          final filledHeight = b.maxValue > 0 ? (b.value / b.maxValue) * totalHeight : 0.0;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${b.value.toInt()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: b.isToday ? colors.primary : colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: totalHeight.clamp(4.0, 100.0),
                  width: 28,
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: filledHeight.clamp(0.0, 100.0),
                    width: 28,
                    decoration: BoxDecoration(
                      color: b.isToday ? colors.primary : colors.primary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  b.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: b.isToday ? FontWeight.w800 : FontWeight.w600,
                    color: b.isToday ? colors.primary : colors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 데이터 모델 ──

class _BarData {
  final String label;
  final double value;
  final double maxValue;
  final bool isToday;

  _BarData({
    required this.label,
    required this.value,
    required this.maxValue,
    this.isToday = false,
  });
}

class _StreakData {
  final String title;
  final int current;
  final int max;

  _StreakData({
    required this.title,
    required this.current,
    required this.max,
  });
}
