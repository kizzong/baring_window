import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingPage7 extends StatefulWidget {
  const OnboardingPage7({super.key, this.onRatingDone});

  final VoidCallback? onRatingDone;

  @override
  State<OnboardingPage7> createState() => _OnboardingPage7State();
}

class _OnboardingPage7State extends State<OnboardingPage7> {
  int _rating = 0;
  bool _hasActioned = false;

  bool get isReady => _rating > 0;

  Future<void> _openStoreReview() async {
    final Uri url;
    if (Platform.isAndroid) {
      url = Uri.parse('market://details?id=com.example.baring_windows');
    } else {
      url = Uri.parse('https://apps.apple.com/app/id6743991553?action=write-review');
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _openKakaoChat() async {
    final url = Uri.parse('https://open.kakao.com/o/sdDlLufi');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _onStarTap(int star) {
    setState(() {
      _rating = star;
      _hasActioned = false;
    });
  }

  void _handleAction() {
    if (_rating >= 4) {
      _openStoreReview();
    } else {
      _openKakaoChat();
    }
    setState(() {
      _hasActioned = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                const Spacer(flex: 2),

                Image.asset(
                  'assets/r-8.cheering_face.png',
                  width: 120,
                  height: 120,
                ),

                const SizedBox(height: 24),

                const Text(
                  '바링은 어떠세요?',
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
                  '소중한 의견이 큰 힘이 돼요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 36),

                // Star rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return GestureDetector(
                      onTap: () => _onStarTap(star),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          star <= _rating ? Icons.star : Icons.star_border,
                          size: 44,
                          color: star <= _rating
                              ? const Color(0xFFFFD54F)
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Action suggestion
                if (_rating > 0 && !_hasActioned) ...[
                  Text(
                    _rating >= 4
                        ? '좋은 평가 감사해요! 스토어에 리뷰를 남겨주세요'
                        : '아쉬운 점이 있으시군요. 의견을 보내주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _handleAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _rating >= 4
                            ? const Color(0xFF3E7BFF)
                            : const Color(0xFFFFE812),
                        foregroundColor:
                            _rating >= 4 ? Colors.white : const Color(0xFF3C1E1E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _rating >= 4 ? '스토어 리뷰 남기기' : '카톡으로 의견 보내기',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
