import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color scaffoldBg;
  final Color cardBg;
  final Color dialogBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color subtle;
  final Color borderColor;
  final Color primary;
  final Color bottomNavBg;
  final Color inputBg;
  final Color chipBg;
  final Color analysisBg;
  final Brightness brightness;

  const AppColors({
    required this.scaffoldBg,
    required this.cardBg,
    required this.dialogBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.subtle,
    required this.borderColor,
    required this.primary,
    required this.bottomNavBg,
    required this.inputBg,
    required this.chipBg,
    required this.analysisBg,
    required this.brightness,
  });

  static const dark = AppColors(
    scaffoldBg: Color(0xFF0B1623),
    cardBg: Color(0xFF121E2B),
    dialogBg: Color(0xFF1A2332),
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
    subtle: Color(0xFF7B8DA0),
    borderColor: Color(0x12FFFFFF), // white.withOpacity(0.07)
    primary: Color(0xFF2D86FF),
    bottomNavBg: Color(0xFF0B1623),
    inputBg: Color(0xFF0B131C),
    chipBg: Color(0xFF0F2538),
    analysisBg: Color(0xFF0F1F2E),
    brightness: Brightness.dark,
  );

  static const light = AppColors(
    scaffoldBg: Color(0xFFF2F3F5),
    cardBg: Color(0xFFFFFFFF),
    dialogBg: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF6B7280),
    subtle: Color(0xFF6B7280),
    borderColor: Color(0x14000000), // black.withOpacity(0.08)
    primary: Color(0xFF2D86FF),
    bottomNavBg: Color(0xFFFFFFFF),
    inputBg: Color(0xFFF5F5F5),
    chipBg: Color(0xFFE8F0FE),
    analysisBg: Color(0xFFF0F4F8),
    brightness: Brightness.dark, // kept dark for CupertinoDatePicker compatibility
  );

  @override
  AppColors copyWith({
    Color? scaffoldBg,
    Color? cardBg,
    Color? dialogBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? subtle,
    Color? borderColor,
    Color? primary,
    Color? bottomNavBg,
    Color? inputBg,
    Color? chipBg,
    Color? analysisBg,
    Brightness? brightness,
  }) {
    return AppColors(
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      cardBg: cardBg ?? this.cardBg,
      dialogBg: dialogBg ?? this.dialogBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      subtle: subtle ?? this.subtle,
      borderColor: borderColor ?? this.borderColor,
      primary: primary ?? this.primary,
      bottomNavBg: bottomNavBg ?? this.bottomNavBg,
      inputBg: inputBg ?? this.inputBg,
      chipBg: chipBg ?? this.chipBg,
      analysisBg: analysisBg ?? this.analysisBg,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      dialogBg: Color.lerp(dialogBg, other.dialogBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      bottomNavBg: Color.lerp(bottomNavBg, other.bottomNavBg, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
      analysisBg: Color.lerp(analysisBg, other.analysisBg, t)!,
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

extension AppColorsExtension on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
