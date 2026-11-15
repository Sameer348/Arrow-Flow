import 'dart:io' show Platform;

/// All ad unit ids in one place.
///
/// `isTestMode` MUST stay true during development. The ids below are
/// Google's official public test units — they never generate revenue and
/// are safe to click. Put your production ids in the `_prod*` fields and
/// flip `isTestMode` only for release builds.
///
/// The AdMob *App ID* lives in AndroidManifest.xml / Info.plist (also the
/// official test App ID right now).
abstract final class AdConfig {
  static const bool isTestMode = true;

  // Official Google test ad units.
  static const androidBannerId = 'ca-app-pub-3940256099942544/9214589741';
  static const androidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const androidRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const iosBannerId = 'ca-app-pub-3940256099942544/2435281174';
  static const iosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';
  static const iosRewardedId = 'ca-app-pub-3940256099942544/1712485313';

  // Production units — fill in before release.
  static const _prodAndroidBanner = '';
  static const _prodAndroidInterstitial = '';
  static const _prodAndroidRewarded = '';
  static const _prodIosBanner = '';
  static const _prodIosInterstitial = '';
  static const _prodIosRewarded = '';

  // Frequency rules (spec §58).
  static const levelsBeforeInterstitial = 3;
  static const minimumTimeBetweenInterstitials = Duration(seconds: 90);
  static const launchGracePeriod = Duration(seconds: 60);
  static const rewardedLoadTimeout = Duration(seconds: 8);

  static bool get _prodReady => _prodAndroidBanner.isNotEmpty && _prodIosBanner.isNotEmpty;
  static bool get _useTest => isTestMode || !_prodReady;

  static String get bannerId => Platform.isIOS
      ? (_useTest ? iosBannerId : _prodIosBanner)
      : (_useTest ? androidBannerId : _prodAndroidBanner);

  static String get interstitialId => Platform.isIOS
      ? (_useTest ? iosInterstitialId : _prodIosInterstitial)
      : (_useTest ? androidInterstitialId : _prodAndroidInterstitial);

  static String get rewardedId => Platform.isIOS
      ? (_useTest ? iosRewardedId : _prodIosRewarded)
      : (_useTest ? androidRewardedId : _prodAndroidRewarded);

  static bool get supportedPlatform => Platform.isAndroid || Platform.isIOS;
}
