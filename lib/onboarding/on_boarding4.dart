import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:baring_windows/pages/dday_settings_page.dart' show EventCard;

class OnboardingPage4 extends StatefulWidget {
  const OnboardingPage4({super.key, this.onGoalSaved});

  final VoidCallback? onGoalSaved;

  @override
  State<OnboardingPage4> createState() => OnboardingPage4State();
}

class OnboardingPage4State extends State<OnboardingPage4> {
  final _titleController = TextEditingController(text: '');
  DateTime _startDate = DateTime.now();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  int _selectedPreset = 0;

  static const _presets = [
    _PresetData('(기본)하늘', [Color(0xFF2D86FF), Color(0xFF1B5CFF)]),
    _PresetData('Deep Sea', [Color(0xFF0E2A68), Color(0xFF245BFF)]),
    _PresetData('빨강', [Color(0xFFFF512F), Color(0xFFDD2476)]),
    _PresetData('핑크', [Color(0xFFFF7EB3), Color(0xFFFF758C)]),
    _PresetData('Aurora', [Color(0xFF8A2BE2), Color(0xFFFF3D8D)]),
    _PresetData('Sunset', [Color(0xFFFF8A00), Color(0xFFFF3D5A)]),
    _PresetData('오렌지', [Color(0xFFFF9A5A), Color(0xFFFF5E62)]),
    _PresetData('초록', [Color(0xFF34D399), Color(0xFF059669)]),
    _PresetData('검정', [Color(0xFF2C2F4A), Color(0xFF1A1C2C)]),
    _PresetData('Midnight', [Color(0xFF1B2430), Color(0xFF0F141B)]),
  ];

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _targetDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3E7BFF),
              surface: Color(0xFF0B1623),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_targetDate.isBefore(_startDate)) {
            _targetDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _targetDate = picked;
        }
      });
    }
  }

  Future<void> saveGoal() async {
    final box = Hive.box('baring');

    await box.put('eventCard', {
      'title': _titleController.text.trim(),
      'startDate': _startDate.toIso8601String(),
      'targetDate': _targetDate.toIso8601String(),
      'selectedPreset': _selectedPreset,
    });

    widget.onGoalSaved?.call();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) {
    return DateFormat('yyyy/MM/dd').format(d);
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF3E7BFF);
    final h = MediaQuery.of(context).size.height;
    final gradientColors = _presets[_selectedPreset].colors;

    final total = _targetDate.difference(_startDate).inDays;
    final done = DateTime.now().difference(_startDate).inDays;
    final progress = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final dDiff = _targetDate.difference(DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day,
    )).inDays;
    final days = dDiff < 0 ? 0 : dDiff;

    return Scaffold(
      backgroundColor: const Color(0xFF050A12),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF08101C), Color(0xFF050A12)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.04),

                  const Center(
                    child: Text(
                      '첫 번째 목표를 만들어보세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),

                  SizedBox(height: h * 0.03),

                  // Live preview
                  EventCard(
                    title: _titleController.text.isEmpty
                        ? '나의 목표'
                        : _titleController.text,
                    startDate: _startDate,
                    targetDate: _targetDate,
                    days: days,
                    gradient: gradientColors,
                    progress: progress,
                    percent: percent,
                  ),

                  const SizedBox(height: 28),

                  // Title input
                  _SectionLabel(text: '목표 이름'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    maxLength: 20,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '예: 자격증 합격',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontWeight: FontWeight.w600,
                      ),
                      counterStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date pickers
                  Row(
                    children: [
                      Expanded(
                        child: _DateButton(
                          label: '시작일',
                          date: _fmtDate(_startDate),
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateButton(
                          label: '마감일',
                          date: _fmtDate(_targetDate),
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Color presets
                  _SectionLabel(text: '카드 색상'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final isSelected = _selectedPreset == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedPreset = i),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: _presets[i].colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2.5)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 22)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: h * 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetData {
  final String name;
  final List<Color> colors;
  const _PresetData(this.name, this.colors);
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });
  final String label;
  final String date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
