import 'dart:async';
import 'package:baring_windows/main.dart';
import 'package:baring_windows/services/notification_service.dart';
import 'package:baring_windows/onboarding/on_boarding1.dart';
import 'package:baring_windows/onboarding/on_boarding2.dart';
import 'package:baring_windows/onboarding/on_boarding3.dart';
import 'package:baring_windows/onboarding/on_boarding4.dart';
import 'package:baring_windows/onboarding/on_boarding5.dart';
import 'package:baring_windows/onboarding/on_boarding6.dart';
import 'package:baring_windows/onboarding/on_boarding7.dart';
import 'package:baring_windows/onboarding/on_boarding_service.dart';
import 'package:baring_windows/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  final GlobalKey<OnboardingPage4State> _page4Key = GlobalKey();
  final GlobalKey<OnboardingPage5State> _page5Key = GlobalKey();

  void _goToPage(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  void _nextPage() {
    if (_currentPage < 6) {
      _goToPage(_currentPage + 1);
    }
  }

  void _skip() {
    _goToPage(6);
  }

  void _onGoalSaved() {
    _nextPage();
  }

  void _onProfileSaved() {
    _nextPage();
  }

  ScrollPhysics _getPhysics() {
    if (_currentPage >= 3) {
      return const NeverScrollableScrollPhysics();
    }
    return const ScrollPhysics();
  }

  String _getButtonText() {
    switch (_currentPage) {
      case 0:
      case 1:
        return '다음';
      case 2:
        return '시작하기';
      case 3:
      case 4:
        return '다음';
      case 5:
        return '다음';
      case 6:
        return '바링 시작하기';
      default:
        return '다음';
    }
  }

  void _onButtonPressed() {
    FocusScope.of(context).unfocus();
    switch (_currentPage) {
      case 0:
      case 1:
      case 2:
        _nextPage();
        break;
      case 3:
        _page4Key.currentState?.saveGoal();
        break;
      case 4:
        _page5Key.currentState?.saveProfile();
        break;
      case 5:
        _nextPage();
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              physics: _getPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                if (index == 5) {
                  Future.delayed(const Duration(seconds: 1), () {
                    NotificationService.requestPermission();
                  });
                }
              },
              children: [
                const OnboardingPage1(),
                const OnboardingPage2(),
                const OnboardingPage3(),
                OnboardingPage4(
                  key: _page4Key,
                  onGoalSaved: _onGoalSaved,
                ),
                OnboardingPage5(
                  key: _page5Key,
                  onProfileSaved: _onProfileSaved,
                ),
                const OnboardingPage6(),
                const OnboardingPage7(),
              ],
            ),
          ),

          // Bottom controls
          Container(
            color: c.scaffoldBg,
            padding: EdgeInsets.only(
              bottom: bottomPadding + h * 0.02,
              top: h * 0.015,
            ),
            child: Column(
              children: [
                SmoothPageIndicator(
                  controller: _controller,
                  count: 7,
                  effect: WormEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    spacing: 12,
                    dotColor: c.textPrimary.withOpacity(0.3),
                    activeDotColor: c.primary,
                  ),
                ),
                SizedBox(height: h * 0.02),

                if (_currentPage == 6)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Row(
                      children: [
                        SizedBox(
                          width: h * 0.068,
                          height: h * 0.068,
                          child: ElevatedButton(
                            onPressed: () => _goToPage(_currentPage - 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.textPrimary.withOpacity(0.10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: c.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: h * 0.068,
                            child: GestureDetector(
                              onTap: () {
                                OnboardingService.completeOnboarding();
                                Navigator.of(context).pushAndRemoveUntil(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, _) =>
                                        const MainAppScreen(),
                                    transitionsBuilder:
                                        (context, animation, _, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration:
                                        const Duration(milliseconds: 500),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3E7BFF),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '바링 시작하기',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_currentPage > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: Row(
                      children: [
                        SizedBox(
                          width: h * 0.068,
                          height: h * 0.068,
                          child: ElevatedButton(
                            onPressed: () => _goToPage(_currentPage - 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.textPrimary.withOpacity(0.10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: c.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: h * 0.068,
                            child: ElevatedButton(
                              onPressed: _onButtonPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: c.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                _getButtonText(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: c.scaffoldBg,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: w * 0.88,
                    height: h * 0.068,
                    child: ElevatedButton(
                      onPressed: _onButtonPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _getButtonText(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: c.scaffoldBg,
                        ),
                      ),
                    ),
                  ),

                // Skip button (pages 1-6, hidden on page 7)
                if (_currentPage < 6) ...[
                  SizedBox(height: h * 0.01),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      '건너뛰기',
                      style: TextStyle(
                        color: c.subtle,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
