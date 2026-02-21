import 'package:flutter/material.dart';
import 'package:baring_windows/services/notification_service.dart';

class OnboardingPage6 extends StatefulWidget {
  const OnboardingPage6({super.key});

  static Future<void> requestNotificationPermission() async {
    await NotificationService.requestPermission();
  }

  @override
  State<OnboardingPage6> createState() => _OnboardingPage6State();
}

class _OnboardingPage6State extends State<OnboardingPage6> {
  bool _permissionRequested = false;

  Future<void> _onPermissionTap() async {
    try {
      final granted = await NotificationService.requestPermission();
      if (mounted) {
        setState(() => _permissionRequested = granted);
      }
    } catch (_) {
      // 권한 요청 실패 시 무시
    }
  }

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
                child: Icon(
                  _permissionRequested
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
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

              const SizedBox(height: 32),

              // Permission button
              SizedBox(
                width: 220,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _permissionRequested ? null : _onPermissionTap,
                  icon: Icon(
                    _permissionRequested
                        ? Icons.check_circle_rounded
                        : Icons.notifications_active_rounded,
                    size: 22,
                  ),
                  label: Text(
                    _permissionRequested ? '알림 허용 완료' : '알림 허용하기',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _permissionRequested
                        ? Colors.white.withOpacity(0.10)
                        : primaryBlue,
                    disabledBackgroundColor: Colors.white.withOpacity(0.10),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
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
