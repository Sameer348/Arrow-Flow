import 'package:arrow_flow/services/ads/ad_frequency_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var now = DateTime(2026, 1, 1, 12);
  AdFrequencyManager make() => AdFrequencyManager(clock: () => now);

  setUp(() => now = DateTime(2026, 1, 1, 12));

  test('never right after launch, never in tutorial, never when disabled', () {
    final f = make();
    for (var i = 0; i < 5; i++) {
      f.onLevelCompleted();
    }
    expect(f.shouldShowInterstitial(adsEnabled: true), isFalse); // launch grace
    now = now.add(const Duration(minutes: 2));
    expect(f.shouldShowInterstitial(adsEnabled: true, inTutorial: true), isFalse);
    expect(f.shouldShowInterstitial(adsEnabled: false), isFalse);
    expect(f.shouldShowInterstitial(adsEnabled: true), isTrue);
  });

  test('every 3 levels and at least 90 s apart', () {
    final f = make();
    now = now.add(const Duration(minutes: 5));
    f.onLevelCompleted();
    f.onLevelCompleted();
    expect(f.shouldShowInterstitial(adsEnabled: true), isFalse);
    f.onLevelCompleted();
    expect(f.shouldShowInterstitial(adsEnabled: true), isTrue);
    f.onInterstitialShown();
    for (var i = 0; i < 3; i++) {
      f.onLevelCompleted();
    }
    now = now.add(const Duration(seconds: 60));
    expect(f.shouldShowInterstitial(adsEnabled: true), isFalse);
    now = now.add(const Duration(seconds: 31));
    expect(f.shouldShowInterstitial(adsEnabled: true), isTrue);
  });
}
