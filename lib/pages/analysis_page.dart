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

  List<DateTime> _monthDays(DateTime anchor) {
    final first = DateTime(anchor.year, anchor.month, 1);
    final last = DateTime(anchor.year, anchor.month + 1, 0);
    return List.generate(
      last.day,
      (i) => first.add(Duration(days: i)),
    );
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

  // ── 요약 계산 ──

  Map<String, dynamic> _computeSummary() {
    final todos = _getAllTodos();
    final routines = _getAllRoutines();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 이번 주
    final thisWeek = _weekDays(today);
    int thisWeekCompleted = 0;
    int thisWeekTotal = 0;
    for (final d in thisWeek) {
      if (d.isAfter(today)) break;
      thisWeekCompleted += _completedCountForDay(d, todos, routines);
      thisWeekTotal += _totalCountForDay(d, todos, routines);
    }

    // 지난 주
    final lastWeekAnchor = today.subtract(const Duration(days: 7));
    final lastWeek = _weekDays(lastWeekAnchor);
    int lastWeekCompleted = 0;
    int lastWeekTotal = 0;
    for (final d in lastWeek) {
      lastWeekCompleted += _completedCountForDay(d, todos, routines);
      lastWeekTotal += _totalCountForDay(d, todos, routines);
    }

    // 변화율
    final thisRate = thisWeekTotal > 0 ? thisWeekCompleted / thisWeekTotal : 0.0;
    final lastRate = lastWeekTotal > 0 ? lastWeekCompleted / lastWeekTotal : 0.0;
    final changePercent = lastRate > 0
        ? ((thisRate - lastRate) / lastRate * 100).round()
        : (thisRate > 0 ? 100 : 0);

    // 이번 달
    final thisMonth = _monthDays(today);
    int monthCompleted = 0;
    int monthTotal = 0;
    for (final d in thisMonth) {
      if (d.isAfter(today)) break;
      monthCompleted += _completedCountForDay(d, todos, routines);
      monthTotal += _totalCountForDay(d, todos, routines);
    }

    // 베스트/워스트 루틴 (지난 30일, 60% 이상 베스트 / 35% 미만 워스트)
    String bestRoutine = '-';
    String worstRoutine = '-';
    double bestRate = -1;
    double worstRate = 2;

    if (routines.isNotEmpty) {
      final last30 = List.generate(30, (i) => today.subtract(Duration(days: i)));
      for (final r in routines) {
        int active = 0;
        int done = 0;
        for (final d in last30) {
          final weekday = d.weekday;
          final isActive = r['type'] == 'daily' ||
              (r['type'] == 'weekly' && (List<int>.from(r['days'] ?? [])).contains(weekday));
          if (!isActive) continue;
          active++;
          final completions = Map<String, dynamic>.from(r['completions'] ?? {});
          if (completions[_dateKey(d)] == true) done++;
        }
        if (active == 0) continue;
        final rate = done / active;
        if (rate >= 0.6 && rate > bestRate) {
          bestRate = rate;
          bestRoutine = r['title'] ?? '-';
        }
        if (rate < 0.35 && rate < worstRate) {
          worstRate = rate;
          worstRoutine = r['title'] ?? '-';
        }
      }
    }

    return {
      'thisWeekCompleted': thisWeekCompleted,
      'thisWeekTotal': thisWeekTotal,
      'monthCompleted': monthCompleted,
      'monthTotal': monthTotal,
      'changePercent': changePercent,
      'bestRoutine': bestRoutine,
      'worstRoutine': worstRoutine,
    };
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

  List<_BarData> _monthlyBarData() {
    final todos = _getAllTodos();
    final routines = _getAllRoutines();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(today.year, today.month + 1, 0).day;
    final weekCount = ((lastDay - 1) ~/ 7) + 1; // 28일=4주, 29~31일=5주

    final List<_BarData> result = [];

    for (int w = 0; w < weekCount; w++) {
      final weekStart = DateTime(today.year, today.month, 1 + w * 7);
      int completed = 0;
      int total = 0;
      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        if (day.month != today.month) continue;
        if (day.isAfter(today)) continue;
        completed += _completedCountForDay(day, todos, routines);
        total += _totalCountForDay(day, todos, routines);
      }
      result.add(_BarData(
        label: '${w + 1}주',
        value: completed.toDouble(),
        maxValue: total.toDouble(),
        isToday: false,
      ));
    }
    return result;
  }

  // ── 루틴 달성률 (지난 30일) ──

  List<_RoutineAchievement> _routineAchievements() {
    final routines = _getAllRoutines();
    if (routines.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last30 = List.generate(30, (i) => today.subtract(Duration(days: i)));

    return routines.map((r) {
      int active = 0;
      int done = 0;
      for (final d in last30) {
        final weekday = d.weekday;
        final isActive = r['type'] == 'daily' ||
            (r['type'] == 'weekly' && (List<int>.from(r['days'] ?? [])).contains(weekday));
        if (!isActive) continue;
        active++;
        final completions = Map<String, dynamic>.from(r['completions'] ?? {});
        if (completions[_dateKey(d)] == true) done++;
      }
      return _RoutineAchievement(
        title: r['title'] ?? '',
        done: done,
        total: active,
        rate: active > 0 ? done / active : 0.0,
      );
    }).toList()
      ..sort((a, b) => b.rate.compareTo(a.rate));
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

  // ── 요일별 패턴 ──

  List<_DayPattern> _dayPatterns() {
    final todos = _getAllTodos();
    final routines = _getAllRoutines();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last30 = List.generate(30, (i) => today.subtract(Duration(days: i)));

    const dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final completed = List.filled(7, 0);
    final total = List.filled(7, 0);

    for (final d in last30) {
      final idx = d.weekday - 1; // 0=월 ~ 6=일
      completed[idx] += _completedCountForDay(d, todos, routines);
      total[idx] += _totalCountForDay(d, todos, routines);
    }

    return List.generate(7, (i) => _DayPattern(
      label: dayNames[i],
      completed: completed[i],
      total: total[i],
      rate: total[i] > 0 ? completed[i] / total[i] : 0.0,
    ));
  }

  String _patternInsight(List<_DayPattern> patterns) {
    if (patterns.every((p) => p.total == 0)) return '';
    final active = patterns.where((p) => p.total > 0).toList();
    if (active.isEmpty) return '';

    final best = active.reduce((a, b) => a.rate > b.rate ? a : b);
    final worst = active.reduce((a, b) => a.rate < b.rate ? a : b);

    final buffer = StringBuffer();
    buffer.write('${best.label}요일 완료율이 ${(best.rate * 100).round()}%로 가장 높아요.');
    if (best.label != worst.label) {
      buffer.write(' ${worst.label}요일은 ${(worst.rate * 100).round()}%로 가장 낮아요.');
    }
    return buffer.toString();
  }

  // ── 빌드 ──

  bool _isWeekly = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final summary = _computeSummary();
    final hasData = summary['thisWeekTotal'] > 0 || summary['monthTotal'] > 0 || _getAllRoutines().isNotEmpty;

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

                        // 1. 요약 카드
                        _buildSummaryCards(c, summary),
                        const SizedBox(height: 24),

                        // 2. 완료 통계
                        _buildCompletionStats(c, av),
                        const SizedBox(height: 24),

                        // 3. 루틴 달성률
                        _buildRoutineAchievements(c, av),
                        const SizedBox(height: 24),

                        // 4. 연속 기록
                        _buildStreaks(c),
                        const SizedBox(height: 24),

                        // 5. 패턴 분석
                        _buildPatternAnalysis(c, av),
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

  // ── 1. 요약 카드 ──

  Widget _buildSummaryCards(AppColors c, Map<String, dynamic> summary) {
    final change = summary['changePercent'] as int;
    final changeText = change > 0 ? '+$change%' : '$change%';
    final changeColor = change > 0
        ? const Color(0xFF22C55E)
        : change < 0
            ? const Color(0xFFEF4444)
            : c.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, '요약'),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _summaryCard(
                  c,
                  '이번 주',
                  '${summary['thisWeekCompleted']}/${summary['thisWeekTotal']}',
                  subtitle: '전주 대비 $changeText',
                  subtitleColor: changeColor,
                  onTap: () => _showThisWeekDetail(c, summary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  c,
                  '이번 달',
                  '${summary['monthCompleted']}/${summary['monthTotal']}',
                  onTap: () => _showThisMonthDetail(c, summary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _summaryCard(
                  c,
                  '베스트 루틴',
                  summary['bestRoutine'] as String,
                  icon: Icons.emoji_events,
                  iconColor: const Color(0xFFFBBF24),
                  onTap: () => _showRoutineDetail(c, summary['bestRoutine'] as String, isBest: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  c,
                  '워스트 루틴',
                  summary['worstRoutine'] as String,
                  icon: Icons.trending_down,
                  iconColor: const Color(0xFFEF4444),
                  onTap: () => _showRoutineDetail(c, summary['worstRoutine'] as String, isBest: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
    AppColors c,
    String title,
    String value, {
    String? subtitle,
    Color? subtitleColor,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: iconColor ?? c.primary),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right, size: 16, color: c.subtle),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor ?? c.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── 상세 분석 바텀시트 ──

  void _showDetailSheet({
    required AppColors c,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.subtle.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Icon(icon, size: 22, color: iconColor),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close, size: 22, color: c.subtle),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: c.borderColor, height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 이번 주 상세 ──

  void _showThisWeekDetail(AppColors c, Map<String, dynamic> summary) {
    final todos = _getAllTodos();
    final routines = _getAllRoutines();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = _weekDays(today);
    final lastWeekAnchor = today.subtract(const Duration(days: 7));
    final lastWeek = _weekDays(lastWeekAnchor);
    const dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

    final List<Map<String, dynamic>> dailyData = [];
    int bestIdx = -1;
    double bestRate = -1;
    int worstIdx = -1;
    double worstRate = 2;

    for (int i = 0; i < 7; i++) {
      final d = thisWeek[i];
      final isPast = !d.isAfter(today);
      final isToday = _dateKey(d) == _dateKey(today);

      if (isPast) {
        final completed = _completedCountForDay(d, todos, routines);
        final total = _totalCountForDay(d, todos, routines);
        final rate = total > 0 ? completed / total : 0.0;
        dailyData.add({
          'label': dayLabels[i],
          'completed': completed,
          'total': total,
          'rate': rate,
          'isToday': isToday,
          'isPast': true,
        });
        if (total > 0) {
          if (rate > bestRate) { bestRate = rate; bestIdx = i; }
          if (rate < worstRate) { worstRate = rate; worstIdx = i; }
        }
      } else {
        dailyData.add({
          'label': dayLabels[i],
          'completed': 0,
          'total': 0,
          'rate': 0.0,
          'isToday': false,
          'isPast': false,
        });
      }
    }

    int lastWeekCompleted = 0;
    int lastWeekTotal = 0;
    for (final d in lastWeek) {
      lastWeekCompleted += _completedCountForDay(d, todos, routines);
      lastWeekTotal += _totalCountForDay(d, todos, routines);
    }

    final thisWeekCompleted = summary['thisWeekCompleted'] as int;
    final thisWeekTotal = summary['thisWeekTotal'] as int;
    final thisRate = thisWeekTotal > 0 ? (thisWeekCompleted / thisWeekTotal * 100).round() : 0;
    final lastRate = lastWeekTotal > 0 ? (lastWeekCompleted / lastWeekTotal * 100).round() : 0;
    final change = summary['changePercent'] as int;

    _showDetailSheet(
      c: c,
      title: '이번 주 상세',
      icon: Icons.calendar_today,
      iconColor: c.primary,
      children: [
        _buildDetailStats(c, [
          {'label': '완료율', 'value': '$thisRate%', 'color': thisRate >= 70 ? const Color(0xFF22C55E) : thisRate >= 40 ? const Color(0xFFFBBF24) : const Color(0xFFEF4444)},
          {'label': '완료', 'value': '$thisWeekCompleted/$thisWeekTotal', 'color': c.primary},
          {'label': '전주 대비', 'value': '${change > 0 ? "+" : ""}$change%', 'color': change > 0 ? const Color(0xFF22C55E) : change < 0 ? const Color(0xFFEF4444) : c.textSecondary},
        ]),
        const SizedBox(height: 24),
        _buildDetailLabel(c, '주간 비교'),
        const SizedBox(height: 12),
        _buildComparisonRow(c, '지난 주', lastWeekCompleted, lastWeekTotal, lastRate.toDouble()),
        const SizedBox(height: 10),
        _buildComparisonRow(c, '이번 주', thisWeekCompleted, thisWeekTotal, thisRate.toDouble()),
        const SizedBox(height: 24),
        _buildDetailLabel(c, '요일별 현황'),
        const SizedBox(height: 12),
        ...dailyData.asMap().entries.map((entry) {
          final i = entry.key;
          final d = entry.value;
          return _buildDayRow(c, d,
            isBest: i == bestIdx,
            isWorst: i == worstIdx && bestIdx != worstIdx,
          );
        }),
        if (bestIdx >= 0) ...[
          const SizedBox(height: 16),
          _buildDetailInsight(c, _weekInsight(dailyData, bestIdx, worstIdx, change)),
        ],
      ],
    );
  }

  String _weekInsight(List<Map<String, dynamic>> dailyData, int bestIdx, int worstIdx, int change) {
    final buf = StringBuffer();
    final best = dailyData[bestIdx];
    buf.write('${best['label']}요일의 완료율이 ${((best['rate'] as double) * 100).round()}%로 가장 높았어요.');
    if (worstIdx >= 0 && bestIdx != worstIdx) {
      final worst = dailyData[worstIdx];
      buf.write(' ${worst['label']}요일은 ${((worst['rate'] as double) * 100).round()}%로 가장 낮았어요.');
    }
    if (change > 0) {
      buf.write('\n지난 주보다 완료율이 $change% 올랐어요!');
    } else if (change < 0) {
      buf.write('\n지난 주보다 완료율이 ${change.abs()}% 내려갔어요. 화이팅!');
    }
    return buf.toString();
  }

  // ── 이번 달 상세 ──

  void _showThisMonthDetail(AppColors c, Map<String, dynamic> summary) {
    final todos = _getAllTodos();
    final routines = _getAllRoutines();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final monthCompleted = summary['monthCompleted'] as int;
    final monthTotal = summary['monthTotal'] as int;
    final monthRate = monthTotal > 0 ? (monthCompleted / monthTotal * 100).round() : 0;

    final lastDay = DateTime(today.year, today.month + 1, 0).day;
    final weekCount = ((lastDay - 1) ~/ 7) + 1;
    final List<Map<String, dynamic>> weeklyData = [];
    int bestWeek = -1;
    double bestWeekRate = -1;

    for (int w = 0; w < weekCount; w++) {
      final weekStart = DateTime(today.year, today.month, 1 + w * 7);
      int completed = 0;
      int total = 0;
      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        if (day.month != today.month) continue;
        if (day.isAfter(today)) continue;
        completed += _completedCountForDay(day, todos, routines);
        total += _totalCountForDay(day, todos, routines);
      }
      final rate = total > 0 ? completed / total : 0.0;
      if (total > 0 && rate > bestWeekRate) {
        bestWeekRate = rate;
        bestWeek = w;
      }
      weeklyData.add({
        'label': '${w + 1}주차',
        'completed': completed,
        'total': total,
        'rate': rate,
      });
    }

    final monthDays = _monthDays(today);
    final List<Map<String, dynamic>> dayDots = [];
    for (final d in monthDays) {
      if (d.isAfter(today)) break;
      final completed = _completedCountForDay(d, todos, routines);
      final total = _totalCountForDay(d, todos, routines);
      dayDots.add({
        'day': d.day,
        'completed': completed,
        'total': total,
        'rate': total > 0 ? completed / total : 0.0,
        'isToday': _dateKey(d) == _dateKey(today),
      });
    }

    _showDetailSheet(
      c: c,
      title: '이번 달 상세',
      icon: Icons.date_range,
      iconColor: c.primary,
      children: [
        _buildDetailStats(c, [
          {'label': '완료율', 'value': '$monthRate%', 'color': monthRate >= 70 ? const Color(0xFF22C55E) : monthRate >= 40 ? const Color(0xFFFBBF24) : const Color(0xFFEF4444)},
          {'label': '완료', 'value': '$monthCompleted/$monthTotal', 'color': c.primary},
          {'label': '경과일', 'value': '${dayDots.length}일', 'color': c.textSecondary},
        ]),
        const SizedBox(height: 24),
        _buildDetailLabel(c, '주별 현황'),
        const SizedBox(height: 12),
        ...weeklyData.asMap().entries.map((entry) {
          return _buildWeekRow(c, entry.value, isBest: entry.key == bestWeek);
        }),
        const SizedBox(height: 24),
        _buildDetailLabel(c, '일별 완료 현황'),
        const SizedBox(height: 12),
        _buildDayDotsGrid(c, dayDots),
        const SizedBox(height: 12),
        _buildDotLegend(c),
        if (bestWeek >= 0) ...[
          const SizedBox(height: 16),
          _buildDetailInsight(c, '${bestWeek + 1}주차의 완료율이 ${(bestWeekRate * 100).round()}%로 가장 높았어요. ${monthRate >= 70 ? '이번 달 완료율이 높아요! 잘하고 있어요.' : monthRate >= 40 ? '꾸준히 하고 있어요. 조금만 더 힘내봐요!' : '조금 더 노력해봐요! 작은 것부터 시작해보세요.'}'),
        ],
      ],
    );
  }

  // ── 루틴 상세 (베스트/워스트 공용) ──

  void _showRoutineDetail(AppColors c, String routineTitle, {required bool isBest}) {
    if (routineTitle == '-') {
      _showDetailSheet(
        c: c,
        title: isBest ? '베스트 루틴' : '워스트 루틴',
        icon: isBest ? Icons.emoji_events : Icons.trending_down,
        iconColor: isBest ? const Color(0xFFFBBF24) : const Color(0xFFEF4444),
        children: [
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: 0.5,
                    child: Image.asset(
                      isBest
                          ? 'assets/r-8.cheering_face.png'
                          : 'assets/r-6.disappointed_face.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isBest ? '아직 베스트 루틴이 없어요' : '아직 워스트 루틴이 없어요',
                    style: TextStyle(color: c.textSecondary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBest ? '완료율 60% 이상인 루틴이 있으면 표시돼요' : '완료율 35% 미만인 루틴이 있으면 표시돼요',
                    style: TextStyle(color: c.subtle, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
      return;
    }

    final routines = _getAllRoutines();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final routine = routines.firstWhere(
      (r) => r['title'] == routineTitle,
      orElse: () => <String, dynamic>{},
    );
    if (routine.isEmpty) return;

    int activeDays = 0;
    int completedDays = 0;
    final List<Map<String, dynamic>> dayHistory = [];
    final last30 = List.generate(30, (i) => today.subtract(Duration(days: i)));

    for (final d in last30.reversed) {
      final weekday = d.weekday;
      final isActive = routine['type'] == 'daily' ||
          (routine['type'] == 'weekly' && (List<int>.from(routine['days'] ?? [])).contains(weekday));
      if (!isActive) {
        dayHistory.add({'date': d, 'active': false, 'done': false});
        continue;
      }
      activeDays++;
      final completions = Map<String, dynamic>.from(routine['completions'] ?? {});
      final done = completions[_dateKey(d)] == true;
      if (done) completedDays++;
      dayHistory.add({'date': d, 'active': true, 'done': done});
    }

    final rate = activeDays > 0 ? (completedDays / activeDays * 100).round() : 0;

    // 스트릭 계산
    int currentStreak = 0;
    int maxStreak = 0;
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final d = today.subtract(Duration(days: i));
      final weekday = d.weekday;
      final isActive = routine['type'] == 'daily' ||
          (routine['type'] == 'weekly' && (List<int>.from(routine['days'] ?? [])).contains(weekday));
      if (!isActive) continue;
      final completions = Map<String, dynamic>.from(routine['completions'] ?? {});
      if (completions[_dateKey(d)] == true) {
        streak++;
        if (i == 0 || currentStreak > 0) currentStreak = streak;
        if (streak > maxStreak) maxStreak = streak;
      } else {
        if (i == 0) currentStreak = 0;
        streak = 0;
      }
    }

    // 활성 요일
    String activeDaysText;
    if (routine['type'] == 'daily') {
      activeDaysText = '매일';
    } else {
      const dayNames = ['', '월', '화', '수', '목', '금', '토', '일'];
      final days = List<int>.from(routine['days'] ?? []);
      days.sort();
      activeDaysText = days.map((d) => dayNames[d]).join(', ');
    }

    // 최근 4주 주별 달성률
    final List<Map<String, dynamic>> weeklyTrend = [];
    for (int w = 0; w < 4; w++) {
      int wActive = 0;
      int wDone = 0;
      for (int d = 0; d < 7; d++) {
        final day = today.subtract(Duration(days: w * 7 + (6 - d)));
        final weekday = day.weekday;
        final isActive = routine['type'] == 'daily' ||
            (routine['type'] == 'weekly' && (List<int>.from(routine['days'] ?? [])).contains(weekday));
        if (!isActive) continue;
        wActive++;
        final completions = Map<String, dynamic>.from(routine['completions'] ?? {});
        if (completions[_dateKey(day)] == true) wDone++;
      }
      weeklyTrend.add({
        'label': w == 0 ? '이번 주' : '$w주 전',
        'done': wDone,
        'active': wActive,
        'rate': wActive > 0 ? wDone / wActive : 0.0,
      });
    }

    _showDetailSheet(
      c: c,
      title: isBest ? '베스트 루틴' : '워스트 루틴',
      icon: isBest ? Icons.emoji_events : Icons.trending_down,
      iconColor: isBest ? const Color(0xFFFBBF24) : const Color(0xFFEF4444),
      children: [
        // 루틴 이름 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.analysisBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isBest ? Icons.emoji_events : Icons.trending_down,
                      size: 36,
                      color: isBest ? const Color(0xFFFBBF24) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      routineTitle,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(activeDaysText, style: TextStyle(fontSize: 13, color: c.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Image.asset(
                isBest
                    ? 'assets/r-8.cheering_face.png'
                    : 'assets/r-6.disappointed_face.png',
                width: 90,
                height: 90,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 핵심 통계
        _buildDetailStats(c, [
          {'label': '달성률', 'value': '$rate%', 'color': rate >= 80 ? const Color(0xFF22C55E) : rate >= 50 ? const Color(0xFFFBBF24) : const Color(0xFFEF4444)},
          {'label': '완료', 'value': '$completedDays/$activeDays', 'color': c.primary},
          {'label': '연속', 'value': '${currentStreak}일', 'color': currentStreak > 0 ? const Color(0xFFF97316) : c.textSecondary},
        ]),
        const SizedBox(height: 24),

        // 연속 기록
        _buildDetailLabel(c, '연속 기록'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.scaffoldBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.local_fire_department,
                      size: 28,
                      color: currentStreak > 0 ? const Color(0xFFF97316) : c.subtle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentStreak}일',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: currentStreak > 0 ? const Color(0xFFF97316) : c.textSecondary,
                      ),
                    ),
                    Text('현재 연속', style: TextStyle(fontSize: 12, color: c.textSecondary)),
                  ],
                ),
              ),
              Container(width: 1, height: 50, color: c.borderColor),
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.military_tech, size: 28, color: const Color(0xFFFBBF24)),
                    const SizedBox(height: 4),
                    Text(
                      '${maxStreak}일',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    Text('최대 연속', style: TextStyle(fontSize: 12, color: c.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 주별 추이
        _buildDetailLabel(c, '주별 추이'),
        const SizedBox(height: 12),
        ...weeklyTrend.reversed.map((w) {
          final wRate = w['rate'] as double;
          return _buildComparisonRow(
            c,
            w['label'] as String,
            w['done'] as int,
            w['active'] as int,
            w['active'] > 0 ? (wRate * 100) : 0,
          );
        }).expand((widget) sync* {
          yield widget;
          yield const SizedBox(height: 8);
        }),
        const SizedBox(height: 16),

        // 최근 30일 현황
        _buildDetailLabel(c, '최근 30일 현황'),
        const SizedBox(height: 12),
        _buildRoutineDotGrid(c, dayHistory),
        const SizedBox(height: 12),
        _buildRoutineDotLegend(c),
        const SizedBox(height: 16),

        // 인사이트
        _buildDetailInsight(c, _routineInsight(routineTitle, rate, currentStreak, maxStreak, isBest)),
      ],
    );
  }

  String _routineInsight(String title, int rate, int currentStreak, int maxStreak, bool isBest) {
    final buf = StringBuffer();
    if (isBest) {
      buf.write('"$title" 루틴의 달성률이 $rate%로 가장 꾸준히 실천하고 있어요!');
      if (currentStreak > 0) {
        buf.write(' 현재 $currentStreak일 연속 진행 중이에요.');
      }
      if (maxStreak > currentStreak && maxStreak > 0) {
        buf.write(' 최고 기록 ${maxStreak}일에 도전해보세요!');
      }
    } else {
      buf.write('"$title" 루틴의 달성률이 $rate%로 개선이 필요해요.');
      if (rate < 20) {
        buf.write(' 매일 작은 것부터 시작해보세요.');
      } else {
        buf.write(' 조금만 더 꾸준히 하면 좋아질 거예요!');
      }
      if (currentStreak > 0) {
        buf.write(' 현재 $currentStreak일 연속 중이니 이어가봐요!');
      }
    }
    return buf.toString();
  }

  // ── 상세 분석 공용 위젯 ──

  Widget _buildDetailStats(AppColors c, List<Map<String, dynamic>> stats) {
    return Row(
      children: stats.asMap().entries.map((entry) {
        final s = entry.value;
        final isLast = entry.key == stats.length - 1;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: c.scaffoldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  s['value'] as String,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: s['color'] as Color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s['label'] as String,
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailLabel(AppColors c, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: c.textPrimary,
      ),
    );
  }

  Widget _buildComparisonRow(AppColors c, String label, int completed, int total, double ratePercent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.scaffoldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary),
              ),
              const Spacer(),
              Text(
                '$completed/$total (${ratePercent.round()}%)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              minHeight: 6,
              backgroundColor: c.textPrimary.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation(c.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(AppColors c, Map<String, dynamic> d, {bool isBest = false, bool isWorst = false}) {
    final isPast = d['isPast'] as bool;
    final isToday = d['isToday'] as bool;
    final label = d['label'] as String;
    final completed = d['completed'] as int;
    final total = d['total'] as int;
    final rate = d['rate'] as double;

    Color dotColor;
    if (!isPast || total == 0) {
      dotColor = c.subtle.withOpacity(0.3);
    } else if (rate >= 0.8) {
      dotColor = const Color(0xFF22C55E);
    } else if (rate >= 0.5) {
      dotColor = const Color(0xFFFBBF24);
    } else {
      dotColor = const Color(0xFFEF4444);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isToday ? c.primary.withOpacity(0.08) : c.scaffoldBg,
        borderRadius: BorderRadius.circular(10),
        border: isToday ? Border.all(color: c.primary.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 28,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                color: isToday ? c.primary : c.textPrimary,
              ),
            ),
          ),
          if (isToday) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(4)),
              child: const Text('오늘', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 8),
          ],
          if (isBest && isPast && total > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Best', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF22C55E))),
            ),
            const SizedBox(width: 8),
          ],
          if (isWorst && isPast && total > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Low', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
            ),
            const SizedBox(width: 8),
          ],
          const Spacer(),
          if (isPast && total > 0) ...[
            Text(
              '$completed/$total',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 42,
              child: Text(
                '${(rate * 100).round()}%',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: dotColor),
              ),
            ),
          ] else
            Text(
              isPast ? '없음' : '-',
              style: TextStyle(fontSize: 14, color: c.subtle),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekRow(AppColors c, Map<String, dynamic> w, {bool isBest = false}) {
    final label = w['label'] as String;
    final completed = w['completed'] as int;
    final total = w['total'] as int;
    final rate = w['rate'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isBest ? c.primary.withOpacity(0.08) : c.scaffoldBg,
        borderRadius: BorderRadius.circular(10),
        border: isBest ? Border.all(color: c.primary.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isBest ? c.primary : c.textPrimary,
            ),
          ),
          if (isBest) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: c.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Best', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.primary)),
            ),
          ],
          const Spacer(),
          Text(
            '$completed/$total',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            child: Text(
              total > 0 ? '${(rate * 100).round()}%' : '-',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: total > 0
                    ? (rate >= 0.8 ? const Color(0xFF22C55E) : rate >= 0.5 ? const Color(0xFFFBBF24) : const Color(0xFFEF4444))
                    : c.subtle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDotsGrid(AppColors c, List<Map<String, dynamic>> days) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: days.map((d) {
        final rate = d['rate'] as double;
        final total = d['total'] as int;
        final isToday = d['isToday'] as bool;

        Color dotColor;
        if (total == 0) {
          dotColor = c.subtle.withOpacity(0.2);
        } else if (rate >= 0.8) {
          dotColor = const Color(0xFF22C55E);
        } else if (rate >= 0.5) {
          dotColor = const Color(0xFFFBBF24);
        } else if (rate > 0) {
          dotColor = const Color(0xFFEF4444);
        } else {
          dotColor = c.subtle.withOpacity(0.3);
        }

        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: dotColor.withOpacity(isToday ? 1.0 : 0.7),
            borderRadius: BorderRadius.circular(8),
            border: isToday ? Border.all(color: c.primary, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '${d['day']}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: total > 0 && rate > 0 ? Colors.white : c.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDotLegend(AppColors c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(c, const Color(0xFF22C55E), '80%+'),
        const SizedBox(width: 16),
        _legendDot(c, const Color(0xFFFBBF24), '50%+'),
        const SizedBox(width: 16),
        _legendDot(c, const Color(0xFFEF4444), '50%-'),
        const SizedBox(width: 16),
        _legendDot(c, c.subtle.withOpacity(0.3), '없음'),
      ],
    );
  }

  Widget _legendDot(AppColors c, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: c.textSecondary)),
      ],
    );
  }

  Widget _buildRoutineDotGrid(AppColors c, List<Map<String, dynamic>> dayHistory) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: dayHistory.map((d) {
        final active = d['active'] as bool;
        final done = d['done'] as bool;
        final date = d['date'] as DateTime;

        Color dotColor;
        if (!active) {
          dotColor = c.subtle.withOpacity(0.1);
        } else if (done) {
          dotColor = const Color(0xFF22C55E);
        } else {
          dotColor = const Color(0xFFEF4444).withOpacity(0.5);
        }

        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: dotColor,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : c.subtle,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoutineDotLegend(AppColors c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(c, const Color(0xFF22C55E), '완료'),
        const SizedBox(width: 16),
        _legendDot(c, const Color(0xFFEF4444).withOpacity(0.5), '미완료'),
        const SizedBox(width: 16),
        _legendDot(c, c.subtle.withOpacity(0.1), '비활성'),
      ],
    );
  }

  Widget _buildDetailInsight(AppColors c, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.analysisBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: c.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: c.textPrimary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. 완료 통계 ──

  Widget _buildCompletionStats(AppColors c, double animValue) {
    final bars = _isWeekly ? _weeklyBarData() : _monthlyBarData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle(c, '완료 통계'),
            const Spacer(),
            _toggleChip(c, '주간', _isWeekly, () => setState(() => _isWeekly = true)),
            const SizedBox(width: 6),
            _toggleChip(c, '월간', !_isWeekly, () => setState(() => _isWeekly = false)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderColor),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              final isNewWeekly = child.key == const ValueKey('weekly');
              final offset = isNewWeekly
                  ? Offset(-1.0, 0.0)
                  : Offset(1.0, 0.0);
              return SlideTransition(
                position: Tween<Offset>(begin: offset, end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _BarChart(
              key: ValueKey(_isWeekly ? 'weekly' : 'monthly'),
              bars: bars,
              colors: c,
              animValue: animValue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleChip(AppColors c, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.chipBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : c.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── 3. 루틴 달성률 ──

  Widget _buildRoutineAchievements(AppColors c, double animValue) {
    final achievements = _routineAchievements();
    if (achievements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, '루틴 달성률'),
        const SizedBox(height: 4),
        Text(
          '지난 30일 기준',
          style: TextStyle(fontSize: 12, color: c.textSecondary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderColor),
          ),
          child: Column(
            children: achievements.asMap().entries.map((entry) {
              final a = entry.value;
              final isLast = entry.key == achievements.length - 1;
              final percent = (a.rate * 100).round();
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$percent%  (${a.done}/${a.total})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: a.rate * animValue,
                        minHeight: 8,
                        backgroundColor: c.textPrimary.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation(
                          _achievementColor(a.rate),
                        ),
                      ),
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

  Color _achievementColor(double rate) {
    if (rate >= 0.8) return const Color(0xFF22C55E);
    if (rate >= 0.5) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
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

  // ── 5. 패턴 분석 ──

  Widget _buildPatternAnalysis(AppColors c, double animValue) {
    final patterns = _dayPatterns();
    final insight = _patternInsight(patterns);
    if (patterns.every((p) => p.total == 0)) return const SizedBox.shrink();

    final maxRate = patterns.map((p) => p.rate).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(c, '요일별 패턴'),
        const SizedBox(height: 4),
        Text(
          '지난 30일 기준',
          style: TextStyle(fontSize: 12, color: c.textSecondary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderColor),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 170,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: patterns.map((p) {
                    final barHeight = maxRate > 0 ? (p.rate / maxRate) * 100 * animValue : 0.0;
                    final isBest = maxRate > 0 && p.rate == maxRate;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${(p.rate * 100).round()}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isBest ? c.primary : c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: barHeight,
                            width: 24,
                            decoration: BoxDecoration(
                              color: isBest ? c.primary : c.primary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (insight.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.analysisBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: c.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insight,
                          style: TextStyle(
                            fontSize: 13,
                            color: c.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── 공통 위젯 ──

  static const _helpTexts = {
    '요약': '[ 이번 주 ]\n'
        '이번 주 월요일~오늘까지 매일의 할일 개수와 루틴 개수를 모두 합산해요.\n\n'
        '예) 월요일: 할일 2개 + 루틴 1개 = 3개\n'
        '화요일: 할일 1개 + 루틴 1개 = 2개\n'
        '\u2192 전체 5개 중 완료한 것이 3개면 "3/5"\n\n'
        '전주 대비는 지난 주 완료율과 이번 주 완료율을 비교한 변화예요.\n'
        '예) 지난 주 4/8(50%) \u2192 이번 주 3/4(75%) = +50%\n\n'
        '[ 이번 달 ]\n'
        '이번 달 1일~오늘까지 매일의 할일+루틴을 모두 합산한 완료 수 / 전체 수예요.\n\n'
        '예) 2월 1일~17일 동안\n'
        '매일 루틴 1개 = 17개\n'
        '특정 날짜 할일 6개 = 6개\n'
        '\u2192 전체 23개, 완료 2개면 "2/23"\n'
        '(23은 날짜가 아니라 할일+루틴의 총 개수예요)\n\n'
        '[ 베스트/워스트 루틴 ]\n'
        '지난 30일간 완료율이 가장 높은 루틴과 가장 낮은 루틴이에요.\n'
        '예) "아침 러닝" 30일 중 25일 완료(83%) \u2192 베스트\n'
        '"독서" 30일 중 5일 완료(17%) \u2192 워스트',
    '완료 통계': '[ 주간 ]\n'
        '이번 주 월~일, 요일별 완료 수를 바 차트로 보여줘요.\n'
        '오늘은 파란색으로 강조돼요.\n\n'
        '예) 화요일에 할일 2개 + 루틴 1개 = 전체 3개\n'
        '그중 1개 완료 \u2192 숫자 "1", 바가 1/3만큼 채워져요.\n\n'
        '[ 월간 ]\n'
        '이번 달을 7일 단위로 나눠서 주별 완료 수를 보여줘요.\n'
        '1주(1~7일), 2주(8~14일), 3주(15~21일), 4주(22~28일)\n'
        '29일 이상인 달은 5주(29~31일)까지 표시돼요.\n\n'
        '예) 3월: 1주~5주(29~31일)\n'
        '2월(28일): 1주~4주\n\n'
        '[ 바 차트 ]\n'
        '회색 바 = 전체 수 (할일+루틴)\n'
        '파란 바 = 완료 수\n'
        '바 위 숫자 = 완료한 개수',
    '루틴 달성률': '지난 30일 동안 각 루틴의 달성률을 보여줘요.\n\n'
        '활성 일수 중 완료한 일수의 비율이에요.\n\n'
        '80% 이상 초록, 50% 이상 노랑, 50% 미만 빨강으로 표시돼요.',
    '연속 기록': '각 루틴의 연속 완료 기록을 보여줘요.\n\n'
        '현재 연속: 오늘부터 거슬러 올라가며 끊기지 않고 완료한 일수예요.\n\n'
        '최대 연속: 최근 1년 내 가장 긴 연속 완료 기록이에요.\n\n'
        '주간 루틴은 해당 요일만 카운트해요.',
    '요일별 패턴': '지난 30일간 요일별 평균 완료율을 보여줘요.\n\n'
        '어떤 요일에 가장 잘 실천하는지, 어떤 요일이 약한지 파악할 수 있어요.\n\n'
        '가장 높은 요일은 파란색으로 강조돼요.',
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

class _RoutineAchievement {
  final String title;
  final int done;
  final int total;
  final double rate;

  _RoutineAchievement({
    required this.title,
    required this.done,
    required this.total,
    required this.rate,
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

class _DayPattern {
  final String label;
  final int completed;
  final int total;
  final double rate;

  _DayPattern({
    required this.label,
    required this.completed,
    required this.total,
    required this.rate,
  });
}
