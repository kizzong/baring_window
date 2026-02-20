import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:baring_windows/theme/app_colors.dart';
import 'package:baring_windows/main.dart' show isDarkMode;
import 'notification_settings_page.dart';
import 'permission_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Box baringBox = Hive.box("baring");

  String userName = '바링';

  final TextEditingController _nameController =
      TextEditingController();
  bool isEditingName = false;

  String? profileImagePath;
  final ImagePicker _picker = ImagePicker();

  void _loadUserName() {
    final savedName = baringBox.get("userName");
    if (savedName != null) {
      setState(() {
        userName = savedName;
        _nameController.text = savedName;
      });
    } else {
      _nameController.text = userName;
    }
  }

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

  Future<void> _openReviewPage() async {
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

    await Future.delayed(Duration(seconds: 1));

    final Uri reviewUrl;

    if (Platform.isAndroid) {
      reviewUrl = Uri.parse('market://details?id=com.example.baring_windows');
    } else if (Platform.isIOS) {
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

  void _showNameEditDialog() {
    final c = context.colors;
    _nameController.text = userName;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: c.dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '이름 변경',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: _nameController,
            maxLength: 10,
            autofocus: true,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: '이름을 입력해주세요',
              hintStyle: TextStyle(
                color: c.subtle,
                fontWeight: FontWeight.w600,
              ),
              counterStyle: TextStyle(color: c.subtle),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: c.borderColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: c.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => isEditingName = false);
              },
              child: Text(
                '취소',
                style: TextStyle(
                  color: c.textPrimary.withOpacity(0.6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _saveProfile();
              },
              child: Text(
                '완료',
                style: TextStyle(
                  color: c.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadUserData();
  }

  void _loadUserData() {
    final savedName = baringBox.get("userName", defaultValue: "바링");
    final savedImagePath = baringBox.get("profileImagePath");

    setState(() {
      userName = savedName;
      _nameController.text = savedName;
      profileImagePath = savedImagePath;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
                          child: profileImagePath != null
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
                          onPressed: _showImageSourceDialog,
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
                _SectionHeader(title: '프로필 정보'),
                const SizedBox(height: 8),
                _CardBox(
                  child: _SettingsRow(
                    title: '이름',
                    trailing: Text(
                      userName,
                      style: TextStyle(
                        color: c.subtle,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        isEditingName = true;
                      });
                      _showNameEditDialog();
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ---------- SECTION: 알림 ----------
                _SectionHeader(title: '알림'),
                const SizedBox(height: 8),
                _CardBox(
                  child: _SettingsRow(
                    title: '할일 알림',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsPage(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ---------- SECTION: 앱 설정 ----------
                _SectionHeader(title: '앱 설정'),
                const SizedBox(height: 8),
                _CardBox(
                  child: Column(
                    children: [
                      _SettingsToggleRow(
                        title: '다크 모드',
                        value: isDarkMode.value,
                        onChanged: (v) {
                          setState(() {});
                          isDarkMode.value = v;
                          baringBox.put('isDarkMode', v);
                        },
                      ),
                      Divider(
                        color: c.textPrimary.withOpacity(0.06),
                        height: 1,
                      ),
                      _SettingsRow(
                        title: '권한 설정',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PermissionSettingsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ---------- SECTION: 평가하기 ----------
                _SectionHeader(title: '평가하기'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '앱이 마음에 드시나요?',
                        style: TextStyle(
                          color: c.textPrimary.withOpacity(0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF2D86FF).withOpacity(0.55),
                                  width: 1.2,
                                ),
                              ),
                              child: TextButton(
                                onPressed: _openReviewPage,
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
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE06A6A).withOpacity(0.55),
                                  width: 1.2,
                                ),
                              ),
                              child: TextButton(
                                onPressed: _showFeedbackDialog,
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- HELPER WIDGETS ----------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      title,
      style: TextStyle(
        color: c.textPrimary.withOpacity(0.60),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderColor),
      ),
      child: child,
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsRow({
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: c.textPrimary.withOpacity(0.3),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              height: 28,
              child: FittedBox(
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.white,
                  activeTrackColor: c.primary,
                  inactiveThumbColor: c.textPrimary.withOpacity(0.9),
                  inactiveTrackColor: c.textPrimary.withOpacity(0.20),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
