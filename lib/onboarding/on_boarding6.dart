import 'package:flutter/material.dart';

class OnboardingPage6 extends StatelessWidget {
  const OnboardingPage6({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF3E7BFF);

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

              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 50,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                '알림을 받아보세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                '할 일 시간이 되면 알려드릴게요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.6,
                  color: Colors.white.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
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
