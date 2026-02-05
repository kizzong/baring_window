import 'package:flutter/material.dart';

class OnboardingPage2 extends StatefulWidget {
  const OnboardingPage2({super.key, this.onNext});

  final VoidCallback? onNext;

  @override
  State<OnboardingPage2> createState() => _OnboardingPage2State();
}

class _OnboardingPage2State extends State<OnboardingPage2> {
  int selectedIndex = 1;

  final List<Color> cardColors = [
    const Color(0xFFFFD54F), // 노랑
    const Color(0xFF3DDC84), // 초록
    const Color(0xFFFF6F7D), // 빨강
    const Color(0xFF3E7BFF), // 파랑
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                // const SizedBox(height: 16),
                const SizedBox(height: 90),

                // 제목
                const Text(
                  '나만의 스타일로 꾸미는 카드',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '다채로운 컬러와 그라데이션으로\n나만의 D-Day를 만드세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: Colors.white.withValues(alpha: 0.55),
                    // color: Color(0xFF6B7684),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 100),

                // 카드 미리보기
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _PreviewCard(color: cardColors[2], rotate: -0.18),
                      _PreviewCard(color: cardColors[0], rotate: 0.18),
                      _PreviewCard(
                        color: cardColors[selectedIndex],
                        rotate: 0,
                        isMain: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 색 선택
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(cardColors.length + 1, (index) {
                    if (index == cardColors.length) {
                      return _ColorAddButton();
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: _ColorDot(
                        color: cardColors[index],
                        isSelected: selectedIndex == index,
                      ),
                    );
                  }),
                ),

                const Spacer(),

                const SizedBox(height: 20),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.color,
    required this.rotate,
    this.isMain = false,
  });

  final Color color;
  final double rotate;
  final bool isMain;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: Container(
        width: isMain ? 320 : 300,
        height: isMain ? 180 : 170,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '목표',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Spacer(),
            Text(
              '자격증 합격',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.isSelected});

  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(color: const Color(0xFF3E7BFF), width: 3)
            : null,
      ),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _ColorAddButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F3F5),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add, color: Color(0xFF9AA4B2)),
    );
  }
}
