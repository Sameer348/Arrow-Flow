import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../services/app_services.dart';
import '../../services/audio/audio_service.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../theme/app_colors.dart';

extension AppContext on BuildContext {
  AppServices get services => read<AppServices>();
  ProgressController get progress => read<ProgressController>();
  AppSettings get settings => read<SettingsController>().settings;
  /// Safe to call from initState (doesn't register an inherited dependency).
  bool get reduceMotion =>
      settings.reduceMotion || WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  /// Standard button feedback: light haptic + click.
  void tapFeedback() {
    services.haptics.light();
    services.audio.play(Sfx.button, volume: 0.5);
  }

  /// Small friendly message. Never shows raw errors.
  void toast(String message, {IconData icon = Icons.info_rounded, Color color = AppColors.primary}) {
    final m = ScaffoldMessenger.maybeOf(this);
    if (m == null) return;
    m
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(milliseconds: 1800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
      ));
  }
}

extension ResponsiveSize on BoxConstraints {
  /// Scale factor relative to a 390pt-wide phone, clamped for tablets.
  double get uiScale => (maxWidth / 390).clamp(0.85, 1.35);
}
