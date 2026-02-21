import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class OnboardingPage5 extends StatefulWidget {
  const OnboardingPage5({super.key, this.onProfileSaved});

  final VoidCallback? onProfileSaved;

  @override
  State<OnboardingPage5> createState() => OnboardingPage5State();
}

class OnboardingPage5State extends State<OnboardingPage5> {
  final _nameController = TextEditingController(text: '바링');

  Future<void> saveProfile() async {
    final box = Hive.box('baring');
    await box.put('userName', _nameController.text.trim());
    widget.onProfileSaved?.call();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF3E7BFF);

    return Scaffold(
      backgroundColor: const Color(0xFF050A12),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Container(
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

                  const Text(
                    '프로필을 설정하세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Name input
                  TextField(
                    controller: _nameController,
                    maxLength: 10,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '이름을 입력하세요',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontWeight: FontWeight.w600,
                      ),
                      counterStyle: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
