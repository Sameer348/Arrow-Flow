import 'package:flutter/animation.dart';

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const page = Duration(milliseconds: 380);

  // Arrow escape stages (spec §26).
  static const anticipation = Duration(milliseconds: 100);
  static const acceleration = Duration(milliseconds: 150);
  static const escape = Duration(milliseconds: 380);
  static const burst = Duration(milliseconds: 320);
  static const blockedFlash = Duration(milliseconds: 220);
}

abstract final class AppCurves {
  static const press = Curves.easeOutCubic;
  static const spring = Curves.elasticOut;
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
}
