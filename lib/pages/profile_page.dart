import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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

  void _saveName() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      setState(() {
        userName = newName;
        isEditingName = false; // 수정 모드 종료 ⭐
      });
      baringBox.put("userName", newName);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserName(); // ← 여기서 호출! ⭐
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
        // actions: [
        //   TextButton(
        //     onPressed: () {},
        //     child: Text(
        //       "완료",
        //       style: TextStyle(
        //         color: Color(0xFF3B82F6),
        //         fontSize: 16,
        //         fontWeight: FontWeight.w700,
        //       ),
        //     ),
        //   ),
        // ],
        actions: isEditingName
            ? [
                TextButton(
                  onPressed: _saveName,
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
      body: SafeArea(
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
                      child: CircleAvatar(
                        backgroundColor: Colors.grey.shade800,
                        radius: 75,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 100,
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
                        onPressed: () {
                          // TODO: 사진 변경 기능 연결
                        },
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
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Premium',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // ---------- SECTION: PERSONAL INFORMATION ----------
              Text(
                '개인 정보',
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
              Text(
                '알림 설정',
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
                  children: [
                    _SwitchRow(
                      title: 'D-Day 알림',
                      desc: '현재 진행중인 목표를 매일 알려줘요',
                      value: ddayAlerts,
                      onChanged: (v) => setState(() => ddayAlerts = v),
                      primary: primary,
                      subtle: subtle,
                      line: line,
                    ),
                    const SizedBox(height: 6),
                    _SwitchRow(
                      title: '목표 진행률 알림',
                      desc: '25%, 50%, 75%, 100% 달성 시 알려줘요.',
                      value: progressAlerts,
                      onChanged: (v) => setState(() => progressAlerts = v),
                      primary: primary,
                      subtle: subtle,
                      line: line,
                    ),
                    const SizedBox(height: 6),
                    _SwitchRow(
                      title: '목표 달성 알림',
                      desc: '목표를 달성하면 축하 알림을 보내줘요.',
                      value: achievementPush,
                      onChanged: (v) => setState(() => achievementPush = v),
                      primary: primary,
                      subtle: subtle,
                      line: line,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ---------- LOG OUT ----------
              Container(
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
                  onPressed: () {
                    // TODO: 로그아웃 처리
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFFE06A6A),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      const Text(
                        '다시 작성',
                        style: TextStyle(
                          color: Color(0xFFE06A6A),
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
