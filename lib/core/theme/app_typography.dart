import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography tokens. One family only. To ship a bundled display font, add it
/// under `assets/fonts/` + pubspec and set [AppTypography.family].
abstract final class AppTypography {
  static const String? family = null; // platform default (SF Pro / Roboto)
}

abstract final class AppTextStyles {
  static const logo = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 44,
    fontWeight: FontWeight.w900,
    letterSpacing: 4,
    height: 1,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static const heading = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  static const subheading = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: AppColors.textMuted,
  );

  static const label = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.textSecondary,
  );

  static const button = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
    color: AppColors.textPrimary,
  );

  static const score = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  static const bigNumber = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: 40,
    fontWeight: FontWeight.w900,
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );
}
