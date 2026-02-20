import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:baring_windows/theme/app_colors.dart';

class PermissionSettingsPage extends StatefulWidget {
  const PermissionSettingsPage({super.key});

  @override
  State<PermissionSettingsPage> createState() =>
      _PermissionSettingsPageState();
}

class _PermissionSettingsPageState extends State<PermissionSettingsPage>
    with WidgetsBindingObserver {
  static const _settingsChannel = MethodChannel('com.baring/settings');

  bool? permCamera;
  bool? permNotification;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    try {
      final result =
          await _settingsChannel.invokeMethod('checkPermissions');
      if (result != null && mounted) {
        setState(() {
          permCamera = result['camera'] as bool?;
          permNotification = result['notification'] as bool?;
        });
      }
    } catch (e) {
      debugPrint('권한 확인 오류: $e');
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await _settingsChannel.invokeMethod('openAppSettings');
    } catch (e) {
      debugPrint('설정 열기 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '설정 > 앱 > 바링 > 권한에서 캘린더를 허용해주세요',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFFF9800),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String desc,
    required bool? granted,
  }) {
    final c = context.colors;
    final bool isGranted = granted == true;
    final Color badgeColor = granted == null
        ? const Color(0xFF64748B)
        : isGranted
            ? const Color(0xFF22C55E)
            : const Color(0xFFEF4444);
    final String badgeText =
        granted == null ? '확인중' : isGranted ? '허용' : '거부';

    return GestureDetector(
      onTap: _openAppSettings,
      child: Container(
        decoration: BoxDecoration(
          color: c.textPrimary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: c.textPrimary.withOpacity(0.05)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: c.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: TextStyle(
                      color: c.subtle,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: c.textPrimary.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.scaffoldBg,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: c.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '권한 설정',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.borderColor),
                ),
                child: Column(
                  children: [
                    _buildPermissionRow(
                      icon: Icons.camera_alt_rounded,
                      title: '사진',
                      desc: '프로필 사진 촬영 및 갤러리 접근',
                      granted: permCamera,
                    ),
                    const SizedBox(height: 8),
                    _buildPermissionRow(
                      icon: Icons.notifications_rounded,
                      title: '알림',
                      desc: '할일 알림 및 일정 알림',
                      granted: permNotification,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
