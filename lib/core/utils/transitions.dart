import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Premium screen transitions (spec §75).
abstract final class Transitions {
  /// Menus → secondary screens: slide up a touch + fade.
  static Route<T> slideFade<T>(Widget page, {Offset from = const Offset(0.0, 0.06)}) => PageRouteBuilder<T>(
        transitionDuration: AppDurations.page,
        reverseTransitionDuration: AppDurations.normal,
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, anim, _, child) {
          final curved = CurvedAnimation(parent: anim, curve: AppCurves.enter, reverseCurve: AppCurves.exit);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(position: Tween(begin: from, end: Offset.zero).animate(curved), child: child),
          );
        },
      );

  /// Side slide (Shop, Settings).
  static Route<T> slide<T>(Widget page) => slideFade(page, from: const Offset(0.12, 0));

  /// Level map → gameplay: zoom in from the tapped node.
  static Route<T> zoom<T>(Widget page) => PageRouteBuilder<T>(
        transitionDuration: const Duration(milliseconds: 460),
        reverseTransitionDuration: AppDurations.normal,
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, anim, _, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutQuart, reverseCurve: Curves.easeInCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(scale: Tween(begin: 1.12, end: 1.0).animate(curved), child: child),
          );
        },
      );

  /// Overlays / results: fade + gentle scale.
  static Route<T> fadeScale<T>(Widget page) => PageRouteBuilder<T>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: AppDurations.slow,
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, anim, _, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(curved), child: child),
          );
        },
      );
}
