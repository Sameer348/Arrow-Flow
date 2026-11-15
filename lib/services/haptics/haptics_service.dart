import 'package:flutter/services.dart';

/// Semantic haptics, throttled so they never spam.
class HapticsService {
  bool enabled = true;
  DateTime _last = DateTime(2000);

  bool _gate([int minMs = 45]) {
    if (!enabled) return false;
    final now = DateTime.now();
    if (now.difference(_last).inMilliseconds < minMs) return false;
    _last = now;
    return true;
  }

  /// Buttons.
  void light() {
    if (_gate()) HapticFeedback.lightImpact();
  }

  /// Successful arrow.
  void medium() {
    if (_gate()) HapticFeedback.mediumImpact();
  }

  /// Blocked arrow.
  void subtle() {
    if (_gate()) HapticFeedback.selectionClick();
  }

  /// Level complete / big moments.
  void strong() {
    if (_gate(0)) HapticFeedback.heavyImpact();
  }
}
