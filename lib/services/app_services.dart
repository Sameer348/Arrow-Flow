import '../game/levels/level_catalog.dart';
import 'ads/admob_service.dart';
import 'analytics/analytics_service.dart';
import 'audio/audio_service.dart';
import 'haptics/haptics_service.dart';

/// Long-lived services, created once in main() and provided to the tree.
class AppServices {
  AppServices({
    required this.audio,
    required this.haptics,
    required this.analytics,
    required this.ads,
    required this.levels,
  });

  final AudioService audio;
  final HapticsService haptics;
  final AnalyticsService analytics;
  final AdMobService ads;
  final LevelCatalog levels;
}
