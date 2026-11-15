import 'ad_config.dart';

/// Decides when an interstitial is allowed. Pure logic, injectable clock,
/// fully unit-testable.
class AdFrequencyManager {
  AdFrequencyManager({
    DateTime Function()? clock,
    this.levelsBetween = AdConfig.levelsBeforeInterstitial,
    this.minGap = AdConfig.minimumTimeBetweenInterstitials,
    this.launchGrace = AdConfig.launchGracePeriod,
  })  : _clock = clock ?? DateTime.now,
        _launchedAt = (clock ?? DateTime.now)();

  final DateTime Function() _clock;
  final int levelsBetween;
  final Duration minGap;
  final Duration launchGrace;
  final DateTime _launchedAt;
  DateTime? _lastShown;
  int _levelsSince = 0;

  void onLevelCompleted() => _levelsSince++;

  bool shouldShowInterstitial({required bool adsEnabled, bool inTutorial = false}) {
    if (!adsEnabled || inTutorial) return false;
    final now = _clock();
    if (now.difference(_launchedAt) < launchGrace) return false;
    if (_levelsSince < levelsBetween) return false;
    final last = _lastShown;
    if (last != null && now.difference(last) < minGap) return false;
    return true;
  }

  void onInterstitialShown() {
    _lastShown = _clock();
    _levelsSince = 0;
  }
}
