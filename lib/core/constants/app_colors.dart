import 'package:flutter/material.dart';

/// App color palette matching product requirements:
/// Primary blue #1565C0, light blue tint #EAF2FB, white, near-black text #1C334E,
/// muted green #2E7D32, muted red #B03A2E, border #D9E2EC, muted text #5C728A.
/// No purple/multi-color gradients, no glassmorphism.
class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color primaryBlueDark = Color(0xFF0D47A1);
  static const Color lightBlueTint = Color(0xFFEAF2FB);
  static const Color background = Color(0xFFF7FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1C334E);
  static const Color textSecondary = Color(0xFF5C728A);
  static const Color textMuted = Color(0xFF8A9BA8);

  static const Color border = Color(0xFFD9E2EC);
  static const Color borderSubtle = Color(0xFFE4EBF2);

  static const Color success = Color(0xFF2E7D32);
  static const Color successTint = Color(0xFFE8F5E9);

  static const Color error = Color(0xFFB03A2E);
  static const Color errorTint = Color(0xFFFDECEA);

  static const Color warning = Color(0xFFE65100);
  static const Color warningTint = Color(0xFFFFF3E0);
}
