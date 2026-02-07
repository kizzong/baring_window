import 'package:animations/animations.dart';
import 'package:baring_windows/main.dart';
import 'package:baring_windows/onboarding/on_boarding1.dart';
import 'package:baring_windows/onboarding/on_boarding2.dart';
import 'package:baring_windows/onboarding/on_boarding3.dart';
import 'package:baring_windows/onboarding/on_boarding4.dart';
import 'package:baring_windows/onboarding/on_boarding_service.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  PageController _controller = PageController();
  bool onLastPage = false;
  bool onThirdPage = false;
  ContainerTransitionType _transitionType =
      ContainerTransitionType.fadeThrough; // ⭐ 전환 타입

  // 온보딩 완료 후 메인 앱으로 이동
  // Future<void> _completeOnboarding() async {
  //   await OnboardingService.completeOnboarding();
  //   if (!mounted) return;
  //   // ⭐ OpenContainer 애니메이션과 함께 화면 전환
  //   Navigator.of(context).pushReplacement(
  //     PageRouteBuilder(
  //       pageBuilder: (context, animation, secondaryAnimation) =>
  //           const MainAppScreen(),
  //       transitionDuration: const Duration(milliseconds: 600),
  //       reverseTransitionDuration: const Duration(milliseconds: 400),
  //       transitionsBuilder: (context, animation, secondaryAnimation, child) {
  //         // Fade + Scale 애니메이션
  //         return FadeTransition(
  //           opacity: animation,
  //           child: ScaleTransition(
  //             scale: Tween<double>(begin: 0.92, end: 1.0).animate(
  //               CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
  //             ),
  //             child: child,
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                onLastPage = (index == 3);
                onThirdPage = (index == 2);
              });
            },
            children: [
              OnboardingPage1(),
              OnboardingPage2(),
              OnboardingPage3(),
              OnboardingPage4(),
            ],
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SmoothPageIndicator(
                  controller: _controller,
                  count: 4,
                  effect: WormEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    spacing: 16,
                    dotColor: Colors.white.withOpacity(0.3),
                    activeDotColor: Colors.white,
                  ),
                ),
                SizedBox(height: 35),

                if (onThirdPage == true)
                  SizedBox(
                    width: 385,
                    height: 62,
                    child: ElevatedButton(
                      onPressed: () {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E7BFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '시작하기',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                // else if (onLastPage == true)
                //   SizedBox(
                //     width: 385,
                //     height: 62,
                //     child: ElevatedButton(
                //       onPressed: _completeOnboarding, // 온보딩 완료 처리,
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: const Color(0xFF3E7BFF),
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(18),
                //         ),
                //         elevation: 0,
                //       ),
                //       child: const Text(
                //         '첫 목표 만들기',
                //         style: TextStyle(
                //           fontSize: 22,
                //           fontWeight: FontWeight.w800,
                //           color: Colors.white,
                //         ),
                //       ),
                //     ),
                //   )
                else if (onLastPage == true)
                  // ⭐ OpenContainer로 감싸기
                  SizedBox(
                    width: 385,
                    height: 62,
                    child: OpenContainer(
                      transitionType: _transitionType,
                      transitionDuration: const Duration(milliseconds: 700),
                      openBuilder: (context, action) {
                        // 온보딩 완료 처리
                        OnboardingService.completeOnboarding();
                        return const MainAppScreen();
                      },
                      closedElevation: 0,
                      closedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      closedColor: const Color(0xFF3E7BFF),
                      openColor: const Color(0xFF0B1623),
                      middleColor: const Color(0xFF1E2F42),
                      closedBuilder: (context, action) {
                        return Container(
                          alignment: Alignment.center,
                          child: const Text(
                            '첫 목표 만들기',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  SizedBox(
                    width: 385,
                    height: 62,
                    child: ElevatedButton(
                      onPressed: () {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E7BFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '다음',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
