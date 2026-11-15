import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../analytics/analytics_service.dart';
import 'ad_config.dart';
import 'ad_frequency_manager.dart';
import 'consent_service.dart';

/// Owns interstitial + rewarded lifecycles. Every method is failure-safe:
/// if ads can't load (offline, no fill, init error) the game simply
/// continues — no freezes, no infinite spinners.
class AdMobService extends ChangeNotifier {
  AdMobService({
    required ConsentService consent,
    required AnalyticsService analytics,
    AdFrequencyManager? frequency,
  })  : _consent = consent, // ignore: prefer_initializing_formals
        _analytics = analytics, // ignore: prefer_initializing_formals
        frequency = frequency ?? AdFrequencyManager();

  final ConsentService _consent;
  final AnalyticsService _analytics;
  final AdFrequencyManager frequency;

  bool _initialized = false;
  bool _canRequest = false;
  bool _adsEnabled = true;
  bool _showingFullScreen = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false;
  Completer<bool>? _rewardedLoad;

  /// Non-rewarded ads on/off (false after "Remove Ads").
  bool get adsEnabled => _adsEnabled;
  set adsEnabled(bool v) {
    if (_adsEnabled == v) return;
    _adsEnabled = v;
    if (!v) {
      _interstitial?.dispose();
      _interstitial = null;
    }
    notifyListeners();
  }

  /// Mirrors the "Personalized Ads" setting; consent still applies on top.
  bool personalized = true;
  AdRequest get request => AdRequest(nonPersonalizedAds: !personalized);

  bool get ready => _initialized && _canRequest;
  bool get bannersAllowed => ready && _adsEnabled;
  bool get isShowingFullScreen => _showingFullScreen;

  Future<void> init() async {
    if (kIsWeb || !AdConfig.supportedPlatform) return;
    try {
      _canRequest = await _consent.gatherConsent();
      if (!_canRequest) return;
      await MobileAds.instance.initialize();
      _initialized = true;
      notifyListeners();
      _loadInterstitial();
      unawaited(_loadRewarded());
    } on Object catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }

  // ---------------------------------------------------------------- Interstitial

  void _loadInterstitial() {
    if (!ready || !_adsEnabled || _interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialId,
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (err) {
          _loadingInterstitial = false;
          debugPrint('Interstitial failed: ${err.message}');
        },
      ),
    );
  }

  void onLevelCompleted() => frequency.onLevelCompleted();

  /// Shows an interstitial at a natural transition *if* rules allow and one
  /// is already loaded. Completes when the ad closes (or immediately).
  Future<void> maybeShowInterstitial({bool inTutorial = false}) async {
    if (!frequency.shouldShowInterstitial(adsEnabled: _adsEnabled && ready, inTutorial: inTutorial)) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _showingFullScreen = true;
        frequency.onInterstitialShown();
        _analytics.log(AnalyticsEvent.interstitialShown);
      },
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _showingFullScreen = false;
        if (!closed.isCompleted) closed.complete();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        _showingFullScreen = false;
        if (!closed.isCompleted) closed.complete();
        _loadInterstitial();
      },
    );
    try {
      await ad.show();
      await closed.future.timeout(const Duration(minutes: 2), onTimeout: () {});
    } on Object catch (e) {
      debugPrint('Interstitial show failed: $e');
      _showingFullScreen = false;
    }
  }

  // ---------------------------------------------------------------- Rewarded

  Future<bool> _loadRewarded() {
    if (_rewarded != null) return Future.value(true);
    if (_rewardedLoad != null) return _rewardedLoad!.future;
    if (!ready) return Future.value(false);
    final c = _rewardedLoad = Completer<bool>();
    RewardedAd.load(
      adUnitId: AdConfig.rewardedId,
      request: request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _rewardedLoad = null;
          if (!c.isCompleted) c.complete(true);
          notifyListeners();
        },
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded failed: ${err.message}');
          _rewardedLoad = null;
          if (!c.isCompleted) c.complete(false);
        },
      ),
    );
    return c.future;
  }

  bool get rewardedReady => _rewarded != null;

  /// Shows a rewarded ad. Resolves to true ONLY if the SDK's
  /// onUserEarnedReward callback fired — never merely because it opened.
  Future<bool> showRewarded({required String placement}) async {
    if (!ready) return false;
    final loaded = await _loadRewarded().timeout(AdConfig.rewardedLoadTimeout, onTimeout: () => false);
    final ad = _rewarded;
    if (!loaded || ad == null) return false;
    _rewarded = null;

    var earned = false;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _showingFullScreen = true,
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _showingFullScreen = false;
        if (!closed.isCompleted) closed.complete();
        unawaited(_loadRewarded());
      },
      onAdFailedToShowFullScreenContent: (a, err) {
        a.dispose();
        _showingFullScreen = false;
        if (!closed.isCompleted) closed.complete();
        unawaited(_loadRewarded());
      },
    );
    try {
      await ad.show(onUserEarnedReward: (_, reward) => earned = true);
      await closed.future.timeout(const Duration(minutes: 3), onTimeout: () {});
    } on Object catch (e) {
      debugPrint('Rewarded show failed: $e');
      _showingFullScreen = false;
      return false;
    }
    if (earned) _analytics.log(AnalyticsEvent.rewardedCompleted, {'placement': placement});
    return earned;
  }

  Future<bool> privacyOptionsRequired() => _consent.privacyOptionsRequired();
  Future<void> showPrivacyOptions() => _consent.showPrivacyOptions();

  @override
  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
    super.dispose();
  }
}
