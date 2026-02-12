import 'package:baring_windows/services/widget_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class DDaySettingsPage extends StatefulWidget {
  const DDaySettingsPage({super.key});

  @override
  State<DDaySettingsPage> createState() => _DDaySettingsPageState();
}

class _DDaySettingsPageState extends State<DDaySettingsPage> {
  Box baringBox = Hive.box("baring");

  final _titleController = TextEditingController();
  String title = '';

  DateTime startDate = DateTime.now();
  DateTime targetDate = DateTime.now();

  int selectedPreset = 0;

  final presets = const [
    _Preset('(기본)하늘', [Color(0xFF2D86FF), Color(0xFF1B5CFF)]),
    _Preset('Deep Sea', [Color(0xFF0E2A68), Color(0xFF245BFF)]),
    _Preset('빨강', [Color(0xFFFF512F), Color(0xFFDD2476)]),
    _Preset('핑크', [Color(0xFFFF7EB3), Color(0xFFFF758C)]),
    _Preset('Aurora', [Color(0xFF8A2BE2), Color(0xFFFF3D8D)]),
    _Preset('Sunset', [Color(0xFFFF8A00), Color(0xFFFF3D5A)]),
    _Preset('오렌지', [Color(0xFFFF9A5A), Color(0xFFFF5E62)]),
    _Preset('초록', [Color(0xFF34D399), Color(0xFF059669)]),
    _Preset('검정', [Color(0xFF2C2F4A), Color(0xFF1A1C2C)]),
    _Preset('Midnight', [Color(0xFF1B2430), Color(0xFF0F141B)]),
  ];
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 저장된 데이터 불러오기 함수
  void _loadData() {
    final eventData = baringBox.get("eventCard");

    if (eventData != null) {
      setState(() {
        _titleController.text = eventData["title"] ?? "";
        title = eventData["title"] ?? "";
        startDate = DateTime.parse(eventData["startDate"]);
        targetDate = DateTime.parse(eventData["targetDate"]);
        final preset = eventData["selectedPreset"] ?? 0;
        selectedPreset = (preset >= 0 && preset < presets.length) ? preset : 0;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? startDate : targetDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              surface: Color(0xFF0E1621),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        startDate = picked;
      } else {
        targetDate = picked;
      }
    });
  }

  int daysRemaining() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return end.difference(today).inDays;
  }

  double progressValue() {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(targetDate.year, targetDate.month, targetDate.day);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final totalDays = end.difference(start).inDays;
    if (totalDays <= 0) return 1.0;

    final passedDays = today.difference(start).inDays;
    final progress = passedDays / totalDays;

    return progress.clamp(0.0, 1.0);
  }

  int progressPercent() {
    return (progressValue() * 100).round();
  }

  void _resetToDefault() {
    setState(() {
      _titleController.clear();
      title = '';
      startDate = DateTime.now();
      targetDate = DateTime.now();
      selectedPreset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = const Color(0xFF101B26);

    final selected = presets[selectedPreset].colors;

    return Scaffold(
      backgroundColor: Color(0xFF0B1623),
      appBar: AppBar(
        backgroundColor: Color(0xFF0B1623),
        centerTitle: true,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.chevron_left),
          color: Color(0xFF3B82F6),
        ),

        title: Text(
          'D-Day 설정',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              baringBox.put("eventCard", {
                "title": _titleController.text,
                "startDate": startDate.toIso8601String(),
                "targetDate": targetDate.toIso8601String(),
                "selectedPreset": selectedPreset,
              });

              // 위젯 업데이트 ⭐
              try {
                await WidgetService.updateWidget();
              } catch (_) {}

              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: Text(
              "완료",
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),

                // Event Details
                _SectionTitle(icon: Icons.calendar_today_rounded, title: '이벤트'),

                const SizedBox(height: 12),
                _GlassCard(
                  color: card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('이벤트'),
                      const SizedBox(height: 8),
                      _InputBox(
                        child: TextField(
                          controller: _titleController,
                          maxLength: 30,
                          onEditingComplete: () {
                            setState(() {
                              title = _titleController.text;
                            });
                          },
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            hintText: '이벤트 제목을 입력하세요',
                            border: InputBorder.none,
                            isDense: true,
                            // counterText: '',
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _Label('시작일'),
                                const SizedBox(height: 8),
                                _InputBox(
                                  onTap: () => _pickDate(isStart: true),
                                  child: Row(
                                    children: [
                                      Text(
                                        fmtDate(startDate),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.calendar_month_rounded,
                                        color: Color(0xFF7B8DA0),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _Label('목표일'),
                                const SizedBox(height: 8),
                                _InputBox(
                                  onTap: () => _pickDate(isStart: false),
                                  child: Row(
                                    children: [
                                      Text(
                                        fmtDate(targetDate),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.calendar_month_rounded,
                                        color: Color(0xFF7B8DA0),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                Row(
                  children: [
                    _SectionTitle(icon: Icons.palette_rounded, title: '색상'),
                    SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        // color: colo,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Primium',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),

                // Card Design
                const SizedBox(height: 12),
                EventCard(
                  title: _titleController.text,
                  startDate: startDate,
                  targetDate: targetDate,
                  days: daysRemaining(),
                  gradient: selected,
                  progress: progressValue(),
                  percent: progressPercent(),
                ),
                const SizedBox(height: 18),
                const _Label('색상 선택'),
                const SizedBox(height: 10),

                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (int i = 0; i < presets.length; i++) ...[
                        _PresetTile(
                          name: presets[i].name,
                          colors: presets[i].colors,
                          selected: selectedPreset == i,
                          onTap: () => setState(() => selectedPreset = i),
                        ),
                        const SizedBox(width: 14),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Delete button
                _DangerButton(text: '다시 작성', onTap: _resetToDefault),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final presets = const [
  _Preset('(기본)하늘', [Color(0xFF2D86FF), Color(0xFF1B5CFF)]),
  _Preset('Deep Sea', [Color(0xFF0E2A68), Color(0xFF245BFF)]),
  _Preset('빨강', [Color(0xFFFF512F), Color(0xFFDD2476)]),
  _Preset('핑크', [Color(0xFFFF7EB3), Color(0xFFFF758C)]),
  _Preset('Aurora', [Color(0xFF8A2BE2), Color(0xFFFF3D8D)]),
  _Preset('Sunset', [Color(0xFFFF8A00), Color(0xFFFF3D5A)]),
  _Preset('오렌지', [Color(0xFFFF9A5A), Color(0xFFFF5E62)]),
  _Preset('초록', [Color(0xFF34D399), Color(0xFF059669)]),
  _Preset('검정', [Color(0xFF2C2F4A), Color(0xFF1A1C2C)]),
  _Preset('Midnight', [Color(0xFF1B2430), Color(0xFF0F141B)]),
];

// 날짜 커스텀 포맷
String fmtDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}/${two(d.month)}/${two(d.day)}';
}

class _Preset {
  final String name;
  final List<Color> colors;
  const _Preset(this.name, this.colors);
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF7B8DA0),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color color;
  const _GlassCard({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: color.withOpacity(0.92),
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

// 입력창 디자인
class _InputBox extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _InputBox({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B131C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: child,
      ),
    );
  }
}

// 색상 선택창 디자인
class _PresetTile extends StatelessWidget {
  final String name;
  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  const _PresetTile({
    required this.name,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              border: Border.all(
                color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: selected
                ? const Center(
                    child: Icon(Icons.check, color: Colors.white, size: 24),
                  )
                : null,
          ),
          // Transform.scale(
          //   scale: 2.1,
          //   child: Transform.translate(
          //     offset: const Offset(7, -3),
          //     child: Container(
          //       padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          //       decoration: BoxDecoration(
          //         color: Colors.black.withValues(alpha: 0.8),
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //       child: Text(
          //         'Primium',
          //         style: TextStyle(
          //           color: Color(0xFF3B82F6),
          //           fontSize: 5,
          //           fontWeight: FontWeight.w600,
          //           letterSpacing: 0.2,
          //         ),
          //       ),
          //     ),
          //   ),
          // ), // 프리미엄
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF7B8DA0),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// 빨간 버튼 디자인
class _DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _DangerButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: const Color(0xFF0B131C),
          border: Border.all(color: const Color(0xFF7A1F26), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4D4D)),
            SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: Color(0xFFFF4D4D),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 이벤트 카드 디자인
class EventCard extends StatefulWidget {
  final String title; // "전기기사"
  final DateTime startDate; // "2024-02-03"
  final DateTime targetDate; // "2024-12-25"
  final int days; // 325
  final List<Color> gradient; // [Color(0xFF667EEA), Color(0xFF64B6FF)]  / 색상 선택
  final double progress; // 0.7 // 칸 채우는 ㅇ
  final int percent; // 70
  final VoidCallback? onMoreTap;

  const EventCard({
    super.key,
    required this.title,
    required this.startDate,
    required this.targetDate,
    required this.days,
    required this.gradient,
    required this.progress,
    required this.percent,
    this.onMoreTap,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  @override
  Widget build(BuildContext context) {
    final total = widget.targetDate.difference(widget.startDate).inDays;
    final done = DateTime.now().difference(widget.startDate).inDays;
    final progress = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    String dDayText(DateTime targetDate) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );

      final diff = target.difference(today).inDays;

      if (diff > 0) return 'D-$diff';
      if (diff == 0) return 'D-DAY';
      return '완료';
    }

    return GestureDetector(
      onTap: widget.onMoreTap,
      child: Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  widget.title.isEmpty ? '이벤트' : widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dDayText(widget.targetDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Spacer(),
              Text(
                '${widget.percent}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(fmtDate(widget.startDate)),
              const Spacer(),
              Text(fmtDate(widget.targetDate)),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
