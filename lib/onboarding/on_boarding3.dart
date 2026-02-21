import 'dart:async';
import 'package:flutter/material.dart';

class OnboardingPage3 extends StatefulWidget {
  const OnboardingPage3({super.key});

  @override
  State<OnboardingPage3> createState() => _OnboardingPage3State();
}

class _OnboardingPage3State extends State<OnboardingPage3> {
  int _currentScene = 0;
  Timer? _timer;

  final _scenes = const [
    _Scene.goalCard,
    _Scene.widget,
    _Scene.todoCheck,
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {
          _currentScene = (_currentScene + 1) % _scenes.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF050A12),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF08101C), Color(0xFF050A12)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                SizedBox(height: h * 0.04),

                const Text(
                  '이렇게 사용해요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.2,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  '목표 관리부터 할 일 체크까지\n한 곳에서 모두 가능해요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: h * 0.02),

                // Phone mock with auto-switching scenes
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Center(
                        child: _PhoneMockCompact(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 600),
                            child: _buildScene(
                              _scenes[_currentScene],
                              constraints.maxWidth * 0.65,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Scene indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Container(
                      width: _currentScene == i ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: _currentScene == i
                            ? const Color(0xFF3E7BFF)
                            : Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScene(_Scene scene, double width) {
    switch (scene) {
      case _Scene.goalCard:
        return FittedBox(
          key: const ValueKey('goal'),
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: Column(
              children: const [
                SizedBox(height: 14),
                _GoalCardCompact(),
              ],
            ),
          ),
        );
      case _Scene.widget:
        return FittedBox(
          key: const ValueKey('widget'),
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: Column(
              children: const [
                SizedBox(height: 14),
                _WidgetCardCompact(),
                SizedBox(height: 34),
                _AppGridCompact(),
              ],
            ),
          ),
        );
      case _Scene.todoCheck:
        return FittedBox(
          key: const ValueKey('todo'),
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: Column(
              children: const [
                SizedBox(height: 14),
                _TodoListCompact(),
              ],
            ),
          ),
        );
    }
  }
}

enum _Scene { goalCard, widget, todoCheck }

// --- Goal Card (reused from old on_boarding1) ---
class _GoalCardCompact extends StatelessWidget {
  const _GoalCardCompact();

  @override
  Widget build(BuildContext context) {
    const cardBlue = Color(0xFF3E7BFF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: cardBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardBlue.withOpacity(0.30),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '목표',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.9), size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Expanded(
                child: Text(
                  '자격증 합격!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'D-32',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '70%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: 0.7,
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '2026.01.25',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '2026.03.30',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Widget Card (reused from old on_boarding3) ---
class _WidgetCardCompact extends StatelessWidget {
  const _WidgetCardCompact();

  @override
  Widget build(BuildContext context) {
    const cardBlue = Color(0xFF3E7BFF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cardBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardBlue.withOpacity(0.26),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  '목표',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.more_horiz, color: Colors.white.withOpacity(0.9), size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Expanded(
                child: Text(
                  '자격증 합격!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'D-32',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '70%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: 0.7,
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '2026.01.25',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '2026.03.30',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- App Grid ---
class _AppGridCompact extends StatelessWidget {
  const _AppGridCompact();

  @override
  Widget build(BuildContext context) {
    final items = [
      _AppIconItem(color: const Color(0xFF3DDC84), icon: Icons.fitness_center, label: 'Fitness'),
      _AppIconItem(color: const Color(0xFFF1F3F5), icon: Icons.calendar_month, label: 'Calendar', iconColor: const Color(0xFF1F2A37)),
      _AppIconItem(color: const Color(0xFF6C63FF), icon: Icons.mail_outline, label: 'Mail'),
      _AppIconItem(color: const Color(0xFFFFB020), icon: Icons.photo_outlined, label: 'Photos'),
      _AppIconItem(color: const Color(0xFF3E7BFF), icon: Icons.flag_outlined, label: ''),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AppIconCompact(items[0]),
            _AppIconCompact(items[1]),
            _AppIconCompact(items[2]),
            _AppIconCompact(items[3]),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: [_AppIconCompact(items[4])]),
      ],
    );
  }
}

class _AppIconItem {
  final Color color;
  final IconData icon;
  final String label;
  final Color? iconColor;
  _AppIconItem({required this.color, required this.icon, required this.label, this.iconColor});
}

class _AppIconCompact extends StatelessWidget {
  const _AppIconCompact(this.item);
  final _AppIconItem item;

  @override
  Widget build(BuildContext context) {
    final iconColor = item.iconColor ?? Colors.white;
    return SizedBox(
      width: 44,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(item.icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.70),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Todo List Preview ---
class _TodoListCompact extends StatelessWidget {
  const _TodoListCompact();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘의 할 일',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        _TodoItem(title: '영어 단어 30개 암기', done: true),
        const SizedBox(height: 8),
        _TodoItem(title: '운동 30분', done: true),
        const SizedBox(height: 8),
        _TodoItem(title: '독서 1시간', done: false),
        const SizedBox(height: 8),
        _TodoItem(title: '일기 쓰기', done: false),
      ],
    );
  }
}

class _TodoItem extends StatelessWidget {
  const _TodoItem({required this.title, required this.done});
  final String title;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(done ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            color: done ? const Color(0xFF3E7BFF) : Colors.white.withOpacity(0.4),
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: done ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: done ? TextDecoration.lineThrough : null,
              decorationColor: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Phone Mock ---
class _PhoneMockCompact extends StatelessWidget {
  const _PhoneMockCompact({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16.5,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(44),
          color: const Color(0xFF0B1623),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 5,
              offset: const Offset(1, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withOpacity(0.10), width: 2),
            color: const Color(0xFF0B1623),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
