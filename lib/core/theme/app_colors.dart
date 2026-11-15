import 'package:flutter/material.dart';

/// Central colour tokens. Nothing else in the app should hardcode a colour;
/// game themes and skins derive from these.
abstract final class AppColors {
  // Surfaces (70% calm / 20% neutral).
  static const background = Color(0xFF0B1020);
  static const backgroundSecondary = Color(0xFF11182B);
  static const surface = Color(0xFF18223A);
  static const surfaceElevated = Color(0xFF202B46);
  static const glass = Color(0x14FFFFFF); // ~8% white
  static const glassBorder = Color(0x1FFFFFFF); // ~12% white
  static const divider = Color(0x14FFFFFF);
  static const scrim = Color(0xB30B1020);

  // Primary accent (10%).
  static const primary = Color(0xFF42E8FF);
  static const secondary = Color(0xFF5B7CFF);

  // Special / premium.
  static const violet = Color(0xFF9B6CFF);
  static const purple = Color(0xFFC084FC);

  // Semantic.
  static const success = Color(0xFF35E0A1);
  static const warning = Color(0xFFFFB84D);
  static const error = Color(0xFFFF5C7A);
  static const coin = warning;

  // Text.
  static const textPrimary = Color(0xFFF8FAFF);
  static const textSecondary = Color(0xFFAAB5CC);
  static const textMuted = Color(0xFF69758F);
  static const textDisabled = Color(0xFF46516A);

  // Arrows.
  static const arrowDefault = primary;
  static const arrowDefaultEnd = secondary;
  static const arrowBlocked = Color(0xFF6C7A99);
  static const arrowSelected = Color(0xFFFFFFFF);

  // Board.
  static const boardTop = Color(0xFF1A2440);
  static const boardBottom = Color(0xFF121A30);
  static const boardCell = Color(0x0DFFFFFF);
  static const boardCellDot = Color(0x1AFFFFFF);
}
