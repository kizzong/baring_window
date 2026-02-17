import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:baring_windows/theme/app_colors.dart';
import 'package:baring_windows/main.dart' show isDarkMode;
import '../services/notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  Box baringBox = Hive.box("baring");

  String userName = '바링';

  final TextEditingController _nameController =
      TextEditingController(); // 컨트롤러 추가 ⭐
  bool isEditingName = false; // 수정 모드 여부 ⭐


  bool morningTodoAlert = false;
  bool eveningTodoAlert = false;
  TimeOfDay morningTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay eveningTime = const TimeOfDay(hour: 21, minute: 0);

  int bottomIndex = 1;
  String? profileImagePath; // 프로필 이미지 경로 추가 ⭐
  final ImagePicker _picker = ImagePicker(); // 이미지 피커 추가 ⭐

  // 권한 상태
  bool? permCamera;
  bool? permNotification;

  static const _settingsChannel = MethodChannel('com.baring/settings');

  void _loadUserName() {
    final savedName = baringBox.get("userName");
    if (savedName != null) {
      setState(() {
        userName = savedName;
        _nameController.text = savedName; // 컨트롤러에도 설정 ⭐
      });
    } else {
      _nameController.text = userName; // 기본값 설정 ⭐
    }
  }

  // 이미지 크롭 함수
  Future<String?> _cropImage(String sourcePath) async {
    final c = context.colors;
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '프로필 사진 편집',
          toolbarColor: c.scaffoldBg,
          toolbarWidgetColor: c.textPrimary,
          backgroundColor: c.scaffoldBg,
          activeControlsWidgetColor: c.primary,
          cropStyle: CropStyle.circle,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: '프로필 사진 편집',
          cancelButtonTitle: '취소',
          doneButtonTitle: '완료',
          cropStyle: CropStyle.circle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    return croppedFile?.path;
  }

  // 이미지 선택 → 크롭 → 저장
  Future<void> _pickAndCropImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      final croppedPath = await _cropImage(image.path);
      if (croppedPath == null) return;

      setState(() {
        profileImagePath = croppedPath;
      });
      await baringBox.put("profileImagePath", croppedPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  '프로필 사진이 변경되었습니다',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            backgroundColor: Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('이미지 선택 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  '이미지를 선택할 수 없습니다',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            backgroundColor: Color(0xFFE06A6A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _saveProfile() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      setState(() {
        userName = newName;
        isEditingName = false;
      });
      baringBox.put("userName", newName);

      // 성공 메시지 표시 ⭐
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text(
                '이름이 변경되었습니다',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          backgroundColor: Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // 이름이 비어있을 때 경고 메시지 ⭐
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text(
                '이름을 입력해주세요',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          backgroundColor: Color(0xFFFF9800),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 이미지 선택 옵션 다이얼로그 ⭐
  Future<void> _showImageSourceDialog() async {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: c.dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: c.primary),
                title: Text('갤러리에서 선택', style: TextStyle(color: c.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndCropImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: c.primary),
                title: Text('카메라로 촬영', style: TextStyle(color: c.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndCropImage(ImageSource.camera);
                },
              ),
              if (profileImagePath != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Color(0xFFE06A6A)),
                  title: Text(
                    '사진 삭제',
                    style: TextStyle(color: Color(0xFFE06A6A)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      profileImagePath = null;
                    });
                    baringBox.delete("profileImagePath");

                    // 삭제 메시지 표시 ⭐
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              '프로필 사진이 삭제되었습니다',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Color(0xFF64748B),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: EdgeInsets.all(16),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // 앱스토어/플레이스토어 리뷰 페이지로 이동 ⭐
  Future<void> _openReviewPage() async {
    // 감사 메시지 먼저 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.favorite, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '감사합니다! 소중한 후기 부탁드려요 💙',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF2D86FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );

    // 1초 대기 후 스토어로 이동 ⭐
    await Future.delayed(Duration(seconds: 1));

    // 플랫폼별 스토어 URL
    final Uri reviewUrl;

    if (Platform.isAndroid) {
      // Google Play 스토어 (패키지명을 실제 앱 패키지명으로 변경하세요)
      reviewUrl = Uri.parse('market://details?id=com.example.baring_windows');
      // 또는 웹 URL: https://play.google.com/store/apps/details?id=com.example.baring_windows
    } else if (Platform.isIOS) {
      // App Store (앱 ID를 실제 앱 ID로 변경하세요)
      reviewUrl = Uri.parse(
        'https://apps.apple.com/app/id6743991553?action=write-review',
      );
    } else {
      return;
    }

    try {
      if (await canLaunchUrl(reviewUrl)) {
        await launchUrl(reviewUrl, mode: LaunchMode.externalApplication);
      } else {
        throw '스토어를 열 수 없습니다';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('리뷰 페이지를 열 수 없습니다'),
            backgroundColor: Color(0xFFE06A6A),
          ),
        );
      }
    }
  }

  // 피드백 다이얼로그 표시 ⭐
  void _showFeedbackDialog() {
    final c = context.colors;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: c.dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.sentiment_dissatisfied,
                color: Color(0xFFFFB74D),
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                '소중한 의견 감사합니다',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '아쉬운 부분이 있으셨군요.\n더 나은 서비스를 제공하기 위해 노력하겠습니다.',
                style: TextStyle(
                  color: c.textPrimary.withOpacity(0.85),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.borderColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.textPrimary.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/kakao_icon.png',
                          width: 18,
                          height: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '카카오톡으로 피드백 보내기',
                          style: TextStyle(
                            color: Color(0xFFFFE812),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '오픈채팅에서 의견을 남겨주세요!',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '닫기',
                style: TextStyle(
                  color: c.textPrimary.withOpacity(0.6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openKakaoFeedback();
              },
              icon: Image.asset('assets/kakao_icon.png', width: 18, height: 18),
              label: Text(
                '카톡으로 보내기',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFE812),
                foregroundColor: Color(0xFF3C1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        );
      },
    );
  }

  // 카카오톡 오픈채팅 피드백 ⭐
  Future<void> _openKakaoFeedback() async {
    final Uri kakaoUrl = Uri.parse('https://open.kakao.com/o/sdDlLufi');

    try {
      if (await canLaunchUrl(kakaoUrl)) {
        await launchUrl(kakaoUrl, mode: LaunchMode.externalApplication);
      } else {
        throw '카카오톡을 열 수 없습니다';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('카카오톡을 열 수 없습니다', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
            backgroundColor: Color(0xFFFF9800),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 4),
          ),
        );
      }
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

  Future<void> _checkPermissions() async {
    try {
      final result = await _settingsChannel.invokeMethod('checkPermissions');
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserName(); // ← 여기서 호출! ⭐
    _loadUserData(); // 함수 이름 수정 ⭐
    _checkPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  void _loadUserData() {
    // 함수 이름 변경 ⭐
    final savedName = baringBox.get("userName", defaultValue: "바링");
    final savedImagePath = baringBox.get("profileImagePath");

    final savedMorning = baringBox.get("morningTodoAlert", defaultValue: false);
    final savedEvening = baringBox.get("eveningTodoAlert", defaultValue: false);
    final savedMorningHour = baringBox.get("morningTimeHour", defaultValue: 8);
    final savedMorningMinute = baringBox.get("morningTimeMinute", defaultValue: 0);
    final savedEveningHour = baringBox.get("eveningTimeHour", defaultValue: 21);
    final savedEveningMinute = baringBox.get("eveningTimeMinute", defaultValue: 0);

    setState(() {
      userName = savedName;
      _nameController.text = savedName;
      profileImagePath = savedImagePath;
      morningTodoAlert = savedMorning;
      eveningTodoAlert = savedEvening;
      morningTime = TimeOfDay(hour: savedMorningHour, minute: savedMorningMinute);
      eveningTime = TimeOfDay(hour: savedEveningHour, minute: savedEveningMinute);
    });
  }

  String _formatTime(TimeOfDay t) {
    final period = t.hour < 12 ? '오전' : '오후';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$period $h:$m';
  }

  Future<TimeOfDay?> _pickNotificationTime(TimeOfDay initial) async {
    final c = context.colors;
    TimeOfDay selected = initial;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: c.scaffoldBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 바
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.textPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: c.textPrimary.withOpacity(0.5),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '알림 시간 설정',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Text(
                        '완료',
                        style: TextStyle(
                          color: c.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // CupertinoDatePicker
              SizedBox(
                height: 220,
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: false,
                    initialDateTime: DateTime(
                      2000, 1, 1, initial.hour, initial.minute,
                    ),
                    onDateTimeChanged: (dt) {
                      selected = TimeOfDay(hour: dt.hour, minute: dt.minute);
                    },
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
            ],
          ),
        );
      },
    );

    if (confirmed == true) return selected;
    return null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose(); // 메모리 해제 ⭐
    super.dispose();
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
    final String badgeText = granted == null ? '확인중' : isGranted ? '허용' : '거부';

    return GestureDetector(
      onTap: _openAppSettings,
      child: Container(
        decoration: BoxDecoration(
          color: c.textPrimary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.textPrimary.withOpacity(0.05)),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

        title: Text(
          '프로필',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: isEditingName
            ? [
                TextButton(
                  onPressed: _saveProfile,
                  child: Text(
                    "완료",
                    style: TextStyle(
                      color: c.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ]
            : [
                TextButton(
                  onPressed: () {},
                  child: Text(
                    "완료",
                    style: TextStyle(
                      color: c.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---------- AVATAR ----------
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c.textPrimary.withOpacity(0.10),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child:
                              profileImagePath !=
                                  null // 이미지 표시 ⭐
                              ? Image.file(
                                  File(profileImagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: c.borderColor,
                                      child: Icon(
                                        Icons.person,
                                        color: c.textSecondary,
                                        size: 100,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: c.borderColor,
                                  child: Icon(
                                    Icons.person,
                                    color: c.textSecondary,
                                    size: 100,
                                  ),
                                ),
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: c.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c.scaffoldBg,
                            width: 3,
                          ),
                        ),
                        child: IconButton(
                          onPressed: _showImageSourceDialog, // 다이얼로그 호출 ⭐
                          icon: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ---------- NAME / SUBTITLE ----------
                Center(
                  child: Text(
                    userName,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c.textPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Primium',
                      style: TextStyle(
                        color: c.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // ---------- SECTION: PERSONAL INFORMATION ----------
                Text(
                  '프로필 정보',
                  style: TextStyle(
                    color: c.textPrimary.withOpacity(0.60),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),

                _CardBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이름',
                        style: TextStyle(
                          color: c.textPrimary.withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: c.borderColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: c.borderColor,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                maxLength: 10,
                                onTap: () {
                                  setState(() {
                                    isEditingName = true; // 수정 모드 활성화
                                  });
                                },
                                // onChanged: (value) {
                                //   setState(() {
                                //     userName = value; // 실시간 반영 ⭐
                                //   });
                                // },
                                onEditingComplete: () {
                                  setState(() {
                                    userName = _nameController.text; // 실시간 반영 ⭐
                                  });
                                },
                                style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  counterText: '', // 글자 수 카운터 숨기기
                                ),
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                // TODO: 이름 수정 dialog 연결
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.edit,
                                  color: c.primary.withOpacity(0.95),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ---------- SECTION: TODO DAILY NOTIFICATIONS ----------
                Text(
                  '할일 알림',
                  style: TextStyle(
                    color: c.textPrimary.withOpacity(0.60),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),

                const SizedBox(height: 10),

                _CardBox(
                  child: Column(
                    children: [
                      // ── 아침 할일 알림 ──
                      _SwitchRow(
                        title: '아침 할일 알림',
                        desc: '매일 ${_formatTime(morningTime)}에 오늘의 할 일을 알려줘요.',
                        value: morningTodoAlert,
                        onChanged: (v) async {
                          if (v) {
                            final picked = await _pickNotificationTime(morningTime);
                            if (picked == null) return;
                            setState(() {
                              morningTodoAlert = true;
                              morningTime = picked;
                            });
                            baringBox.put("morningTodoAlert", true);
                            baringBox.put("morningTimeHour", picked.hour);
                            baringBox.put("morningTimeMinute", picked.minute);
                            NotificationService.refreshDailyNotifications();
                          } else {
                            setState(() => morningTodoAlert = false);
                            baringBox.put("morningTodoAlert", false);
                            NotificationService.cancelMorningNotification();
                          }
                        },
                      ),
                      // 시간 변경 버튼 (ON 상태일 때만)
                      if (morningTodoAlert) ...[
                        const SizedBox(height: 6),
                        _TimeChip(
                          time: _formatTime(morningTime),
                          primary: c.primary,
                          onTap: () async {
                            final picked = await _pickNotificationTime(morningTime);
                            if (picked == null) return;
                            setState(() => morningTime = picked);
                            baringBox.put("morningTimeHour", picked.hour);
                            baringBox.put("morningTimeMinute", picked.minute);
                            NotificationService.refreshDailyNotifications();
                          },
                        ),
                      ],
                      const SizedBox(height: 6),
                      // ── 저녁 할일 알림 ──
                      _SwitchRow(
                        title: '저녁 할일 알림',
                        desc: '매일 ${_formatTime(eveningTime)}에 내일의 할 일을 알려줘요.',
                        value: eveningTodoAlert,
                        onChanged: (v) async {
                          if (v) {
                            final picked = await _pickNotificationTime(eveningTime);
                            if (picked == null) return;
                            setState(() {
                              eveningTodoAlert = true;
                              eveningTime = picked;
                            });
                            baringBox.put("eveningTodoAlert", true);
                            baringBox.put("eveningTimeHour", picked.hour);
                            baringBox.put("eveningTimeMinute", picked.minute);
                            NotificationService.refreshDailyNotifications();
                          } else {
                            setState(() => eveningTodoAlert = false);
                            baringBox.put("eveningTodoAlert", false);
                            NotificationService.cancelEveningNotification();
                          }
                        },
                      ),
                      // 시간 변경 버튼 (ON 상태일 때만)
                      if (eveningTodoAlert) ...[
                        const SizedBox(height: 6),
                        _TimeChip(
                          time: _formatTime(eveningTime),
                          primary: c.primary,
                          onTap: () async {
                            final picked = await _pickNotificationTime(eveningTime);
                            if (picked == null) return;
                            setState(() => eveningTime = picked);
                            baringBox.put("eveningTimeHour", picked.hour);
                            baringBox.put("eveningTimeMinute", picked.minute);
                            NotificationService.refreshDailyNotifications();
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ---------- SECTION: PERMISSION SETTINGS ----------
                Text(
                  '권한 설정',
                  style: TextStyle(
                    color: c.textPrimary.withOpacity(0.60),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),

                _CardBox(
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

                const SizedBox(height: 22),

                // ---------- SECTION: DISPLAY SETTINGS ----------
                Text(
                  '화면 설정',
                  style: TextStyle(
                    color: c.textPrimary.withOpacity(0.60),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),

                _CardBox(
                  child: _SwitchRow(
                    title: '다크 모드',
                    desc: '어두운 화면 테마를 사용합니다.',
                    value: isDarkMode.value,
                    onChanged: (v) {
                      setState(() {});
                      isDarkMode.value = v;
                      baringBox.put('isDarkMode', v);
                    },
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  '평가하기',
                  style: TextStyle(
                    color: c.textPrimary.withOpacity(0.60),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),

                _CardBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '앱이 마음에 드시나요?',
                        style: TextStyle(
                          color: c.textPrimary.withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 54,
                            width: MediaQuery.of(context).size.width * 0.405,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFF2D86FF,
                                ).withOpacity(0.55),
                                width: 1.2,
                              ),
                            ),
                            child: TextButton(
                              onPressed: () {
                                _openReviewPage();
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.thumb_up_outlined,
                                    color: c.textPrimary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '좋아요!',
                                    style: TextStyle(
                                      color: c.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // SizedBox(width: 12),
                          Container(
                            height: 54,
                            width: MediaQuery.of(context).size.width * 0.395,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(
                                  0xFFE06A6A,
                                ).withOpacity(0.55),
                                width: 1.2,
                              ),
                            ),
                            child: TextButton(
                              onPressed: () {
                                _showFeedbackDialog();
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.near_me_outlined,
                                    color: c.textPrimary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '아쉬워요..',
                                    style: TextStyle(
                                      color: c.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ---------- LOG OUT ----------
                // Container(
                //   height: 54,
                //   decoration: BoxDecoration(
                //     color: Colors.transparent,
                //     borderRadius: BorderRadius.circular(16),
                //     border: Border.all(
                //       color: const Color(0xFFE06A6A).withOpacity(0.55),
                //       width: 1.2,
                //     ),
                //   ),
                //   child: TextButton(
                //     onPressed: () {
                //       // TODO: 로그아웃 처리
                //     },
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         const Icon(
                //           Icons.refresh_rounded,
                //           color: Color(0xFFE06A6A),
                //           size: 20,
                //         ),
                //         SizedBox(width: 8),
                //         const Text(
                //           '다시 작성',
                //           style: TextStyle(
                //             color: Color(0xFFE06A6A),
                //             fontSize: 16,
                //             fontWeight: FontWeight.w800,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBox extends StatelessWidget {
  final Widget child;
  const _CardBox({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderColor),
      ),
      child: child,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.desc,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.textPrimary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.textPrimary.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    color: c.subtle,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: c.primary,
            inactiveThumbColor: c.textPrimary.withOpacity(0.9),
            inactiveTrackColor: c.textPrimary.withOpacity(0.20),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final Color primary;
  final VoidCallback onTap;

  const _TimeChip({
    required this.time,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time_rounded, color: primary, size: 18),
            const SizedBox(width: 8),
            Text(
              time,
              style: TextStyle(
                color: primary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.edit_rounded,
              color: primary.withValues(alpha: 0.6),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
