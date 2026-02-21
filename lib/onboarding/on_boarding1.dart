import 'package:flutter/material.dart';

class OnboardingPage1 extends StatefulWidget {
  const OnboardingPage1({super.key});

  @override
  State<OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<OnboardingPage1>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnim;
  late Animation<double> _titleFade;
  late Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _bounceAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
    );

    _subtitleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
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
                const Spacer(flex: 3),

                // Character image with bounce
                ScaleTransition(
                  scale: _bounceAnim,
                  child: Image.asset(
                    'assets/r-9. cheering2_face.png',
                    width: 160,
                    height: 160,
                  ),
                ),

                const SizedBox(height: 32),

                // Title fade-in
                FadeTransition(
                  opacity: _titleFade,
                  child: const Text(
                    '반가워요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Subtitle fade-in
                FadeTransition(
                  opacity: _subtitleFade,
                  child: Text(
                    '바링과 함께 목표를 향해\n한 걸음씩 나아가볼까요?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      color: Colors.white.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      );
  }
}
