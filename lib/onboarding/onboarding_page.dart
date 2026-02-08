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
      ContainerTransitionType.fadeThrough;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF050A12),
      body: Column(
        children: [
          Expanded(
            child: PageView(
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
          ),
          Container(
            color: const Color(0xFF050A12),
            padding: EdgeInsets.only(
              bottom: bottomPadding + h * 0.02,
              top: h * 0.02,
            ),
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
                SizedBox(height: h * 0.02),

                if (onThirdPage == true)
                  SizedBox(
                    width: w * 0.88,
                    height: h * 0.068,
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
                else if (onLastPage == true)
                  SizedBox(
                    width: w * 0.88,
                    height: h * 0.068,
                    child: OpenContainer(
                      transitionType: _transitionType,
                      transitionDuration: const Duration(milliseconds: 700),
                      openBuilder: (context, action) {
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
                    width: w * 0.88,
                    height: h * 0.068,
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
