import 'package:baring_windows/theme/app_colors.dart';
import 'package:flutter/material.dart';

class OnboardingPage6 extends StatelessWidget {
  const OnboardingPage6({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: c.scaffoldBg,
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
                  color: c.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 50,
                  color: c.primary,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                '알림을 받아보세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: c.textPrimary,
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
                  color: c.subtle,
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
