import 'package:flutter/material.dart';

class OnboardingPage4 extends StatelessWidget {
  const OnboardingPage4({super.key, this.onStart});

  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF3E7BFF);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Container(
            width: constraints.maxWidth, // 부모의 최대 너비 사용 ⭐
            height: constraints.maxHeight, // 부모의 최대 높이 사용 ⭐
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
                    const SizedBox(height: 200),
                    // 🎉 아이콘 (선택)
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 100),

                    // 제목
                    const Text(
                      '이제 시작해볼까요?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 설명
                    Text(
                      '첫 목표만 정하면\n바로 시작할 수 있어요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.6,
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const Spacer(),

                    // 페이지 점 (4번째)
                    // const _Dots(activeIndex: 3),
                    const SizedBox(height: 18),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
