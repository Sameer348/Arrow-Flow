import 'package:flutter/foundation.dart';

/// Analytics events the game emits. Back this with Firebase/Amplitude later
/// by implementing [AnalyticsService]; nothing else needs to change.
enum AnalyticsEvent {
  levelStarted('level_started'),
  levelCompleted('level_completed'),
  levelFailed('level_failed'),
  hintUsed('hint_used'),
  boosterUsed('booster_used'),
  rewardedCompleted('rewarded_completed'),
  interstitialShown('interstitial_shown'),
  dailyChallengeStarted('daily_challenge_started'),
  dailyChallengeCompleted('daily_challenge_completed'),
  skinUnlocked('skin_unlocked');

  const AnalyticsEvent(this.name);
  final String name;
}

abstract class AnalyticsService {
  void log(AnalyticsEvent event, [Map<String, Object?> params = const {}]);
}

/// Default: logs to the console in debug builds only. No network.
class DebugAnalyticsService implements AnalyticsService {
  @override
  void log(AnalyticsEvent event, [Map<String, Object?> params = const {}]) {
    if (kDebugMode) debugPrint('[analytics] ${event.name} $params');
  }
}
