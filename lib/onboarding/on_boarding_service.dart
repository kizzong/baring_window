import 'package:hive/hive.dart';

class OnboardingService {
  static const String _onboardingKey = 'hasSeenOnboarding';

  // Hive Box 가져오기 (기존 baring box 사용)
  static Box _getBox() {
    return Hive.box('baring');
  }

  // 온보딩 완료 여부 확인
  static bool hasSeenOnboarding() {
    final box = _getBox();
    return box.get(_onboardingKey, defaultValue: false) as bool;
  }

  // 온보딩 완료 처리
  static Future<void> completeOnboarding() async {
    final box = _getBox();
    await box.put(_onboardingKey, true);
  }

  // 온보딩 리셋 (테스트용)
  static Future<void> resetOnboarding() async {
    final box = _getBox();
    await box.delete(_onboardingKey);
  }
}
