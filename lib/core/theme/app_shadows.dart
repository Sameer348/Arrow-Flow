import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Soft ambient shadows and subtle glows.
abstract final class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const card = [
    BoxShadow(color: Color(0x59000000), blurRadius: 24, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const button = [
    BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
  ];

  static const arrow = [
    BoxShadow(color: Color(0x80000000), blurRadius: 6, offset: Offset(0, 3)),
  ];

  static List<BoxShadow> glow(Color color, {double strength = 1}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35 * strength),
          blurRadius: 24 * strength,
          spreadRadius: -2,
        ),
      ];

  static final cyanGlow = glow(AppColors.primary);
  static final purpleGlow = glow(AppColors.violet);
  static final goldGlow = glow(AppColors.warning);
  static final successGlow = glow(AppColors.success);
}
