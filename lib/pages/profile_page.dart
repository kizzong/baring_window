import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Box baringBox = Hive.box("baring");

  String userName = '바링';

  final TextEditingController _nameController =
      TextEditingController(); // 컨트롤러 추가 ⭐
  bool isEditingName = false; // 수정 모드 여부 ⭐

  bool ddayAlerts = true;
  bool progressAlerts = true;
  bool achievementPush = false;

  int bottomIndex = 1;
  String? profileImagePath; // 프로필 이미지 경로 추가 ⭐
  final ImagePicker _picker = ImagePicker(); // 이미지 피커 추가 ⭐

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

  // 이미지 선택 함수 추가 ⭐
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          profileImagePath = image.path;
        });
        await baringBox.put("profileImagePath", image.path);

        // 성공 메시지 표시 ⭐
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1A2332),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF2F80ED)),
                title: Text('갤러리에서 선택', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFF2F80ED)),
                title: Text('카메라로 촬영', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? photo = await _picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 512,
                      maxHeight: 512,
                      imageQuality: 85,
                    );
                    if (photo != null) {
                      setState(() {
                        profileImagePath = photo.path;
                      });
                      await baringBox.put("profileImagePath", photo.path);

                      // 성공 메시지 표시 ⭐
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  '프로필 사진이 변경되었습니다',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
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
                    }
                  } catch (e) {
                    print('카메라 오류: $e');
                  }
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
        'https://apps.apple.com/app/id1234567890?action=write-review',
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A2332),
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
                  color: Colors.white,
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
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: Color(0xFF3B82F6),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '피드백 보내기',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    SelectableText(
                      'kizzoman@naver.com', // 실제 이메일 주소로 변경하세요 ⭐
                      style: TextStyle(
                        color: Colors.white,
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
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _sendFeedbackEmail();
              },
              icon: Icon(Icons.send, size: 18),
              label: Text(
                '메일 보내기',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3B82F6),
                foregroundColor: Colors.white,
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

  // 피드백 이메일 전송 ⭐
  Future<void> _sendFeedbackEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'feedback@baring.app', // 실제 이메일 주소로 변경하세요 ⭐
      query: Uri.encodeFull(
        'subject=Baring 앱 피드백&body=안녕하세요,\n\n다음과 같은 피드백을 전달드립니다:\n\n',
      ),
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw '메일 앱을 열 수 없습니다';
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
                  child: Text(
                    '메일 앱을 열 수 없습니다\nfeedback@baring.app으로 직접 연락해주세요',
                    style: TextStyle(fontSize: 14),
                  ),
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

  @override
  void initState() {
    super.initState();
    _loadUserName(); // ← 여기서 호출! ⭐
    _loadUserData(); // 함수 이름 수정 ⭐
  }

  void _loadUserData() {
    // 함수 이름 변경 ⭐
    final savedName = baringBox.get("userName", defaultValue: "지호");
    final savedImagePath = baringBox.get("profileImagePath");

    setState(() {
      userName = savedName;
      _nameController.text = savedName;
      profileImagePath = savedImagePath;
    });
  }

  @override
  void dispose() {
    _nameController.dispose(); // 메모리 해제 ⭐
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // const card = Color(0xFF121E2B);
    const line = Color(0xFF263444);
    const subtle = Color(0xFF7B8DA0);
    const primary = Color(0xFF2F80ED);

    return Scaffold(
      backgroundColor: Color(0xFF0B1623),
      appBar: AppBar(
        backgroundColor: Color(0xFF0B1623),
        centerTitle: true,

        title: Text(
          '프로필',
          style: TextStyle(
            color: Colors.white,
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
                      color: Color(0xFF3B82F6),
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
                      color: Color(0xFF3B82F6),
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
                          color: Colors.white.withValues(alpha: 0.10),
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
                                  return CircleAvatar(
                                    backgroundColor: Colors.grey.shade800,
                                    radius: 75,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white70,
                                      size: 100,
                                    ),
                                  );
                                },
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.grey.shade800,
                                radius: 75,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white70,
                                  size: 100,
                                ),
                              ),
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xFF0B1623), width: 3),
                      ),
                      child: IconButton(
                        onPressed: _showImageSourceDialog, // 다이얼로그 호출 ⭐
                        icon: const Icon(
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
                    color: Colors.white,
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
                    color: Colors.white.withValues(alpha: 0.05),
                    // color: colo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Primium',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
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
                  color: Colors.white.withOpacity(0.60),
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
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
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
                                color: Colors.white,
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
                                color: primary.withOpacity(0.95),
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

              // ---------- SECTION: NOTIFICATION PREFERENCES ----------
              Row(
                children: [
                  Text(
                    '알림 설정',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.60),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2538),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: const Text(
                      '준비중...',
                      style: TextStyle(
                        color: Color(0xFF2D86FF),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _CardBox(
                child: Column(
                  children: [
                    _SwitchRow(
                      title: 'D-Day 알림',
                      desc: '현재 진행중인 목표를 매일 알려줘요',
                      // value: ddayAlerts,
                      value: false,
                      onChanged: (v) => setState(() => ddayAlerts = v),
                      primary: primary,
                      subtle: subtle,
                      line: line,
                    ),
                    const SizedBox(height: 6),
                    _SwitchRow(
                      title: '목표 진행률 알림',
                      desc: '25%, 50%, 75%, 100% 달성 시 알려줘요.',
                      // value: progressAlerts,
                      value: false,
                      onChanged: (v) => setState(() => progressAlerts = v),
                      primary: primary,
                      subtle: subtle,
                      line: line,
                    ),
                    const SizedBox(height: 6),
                    _SwitchRow(
                      title: '목표 달성 알림',
                      desc: '목표를 달성하면 축하 알림을 보내줘요.',
                      // value: achievementPush,
                      value: false,
                      onChanged: (v) => setState(() => achievementPush = v),
                      primary: primary,
                      subtle: subtle,
                      line: line,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              Text(
                '평가하기',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.60),
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
                        color: Colors.white.withOpacity(0.85),
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
                              color: const Color(0xFF2D86FF).withOpacity(0.55),
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
                                const Icon(
                                  Icons.thumb_up_outlined,
                                  // color: Color(0xFFE06A6A),
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                const Text(
                                  '좋아요!',
                                  style: TextStyle(
                                    // color: Color(0xFFE06A6A),
                                    color: Colors.white,
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
                              color: const Color(0xFFE06A6A).withOpacity(0.55),
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
                                const Icon(
                                  Icons.near_me_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                const Text(
                                  '아쉬워요..',
                                  style: TextStyle(
                                    color: Colors.white,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121E2B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
  final Color primary;
  final Color subtle;
  final Color line;

  const _SwitchRow({
    required this.title,
    required this.desc,
    required this.value,
    required this.onChanged,
    required this.primary,
    required this.subtle,
    required this.line,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    color: subtle,
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
            activeTrackColor: primary,
            inactiveThumbColor: Colors.white.withValues(alpha: 0.9),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.20),
          ),
        ],
      ),
    );
  }
}
