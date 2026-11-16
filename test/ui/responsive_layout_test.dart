// Renders every screen and overlay at small phone, normal phone and tablet
// sizes, with normal and large text, and fails on any layout overflow.
import 'package:arrow_flow/app.dart';
import 'package:arrow_flow/core/theme/app_theme.dart';
import 'package:arrow_flow/features/achievements/achievements_screen.dart';
import 'package:arrow_flow/features/daily_challenge/daily_challenge_screen.dart';
import 'package:arrow_flow/features/gameplay/game_launch.dart';
import 'package:arrow_flow/features/gameplay/game_screen.dart';
import 'package:arrow_flow/features/gameplay/overlays.dart';
import 'package:arrow_flow/features/home/daily_reward_dialog.dart';
import 'package:arrow_flow/features/home/home_screen.dart';
import 'package:arrow_flow/features/level_map/level_map_screen.dart';
import 'package:arrow_flow/features/modes/modes_screen.dart';
import 'package:arrow_flow/features/profile/profile_screen.dart';
import 'package:arrow_flow/features/settings/settings_screen.dart';
import 'package:arrow_flow/features/shop/shop_screen.dart';
import 'package:arrow_flow/game/engine/game_session.dart';
import 'package:arrow_flow/game/levels/level_catalog.dart';
import 'package:arrow_flow/models/game_mode.dart';
import 'package:arrow_flow/repositories/progress_repository.dart';
import 'package:arrow_flow/services/ads/admob_service.dart';
import 'package:arrow_flow/services/ads/consent_service.dart';
import 'package:arrow_flow/services/analytics/analytics_service.dart';
import 'package:arrow_flow/services/app_services.dart';
import 'package:arrow_flow/services/audio/audio_service.dart';
import 'package:arrow_flow/services/haptics/haptics_service.dart';
import 'package:arrow_flow/state/progress_controller.dart';
import 'package:arrow_flow/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Logical sizes (dp) with status/nav-bar insets, so SafeArea is exercised.
const _devices = <String, (Size, EdgeInsets)>{
  'small 320x568': (Size(320, 568), EdgeInsets.only(top: 20)),
  'compact 360x640': (Size(360, 640), EdgeInsets.only(top: 24, bottom: 48)),
  'phone 412x915': (Size(412, 915), EdgeInsets.only(top: 40, bottom: 24)),
  'tablet 800x1280': (Size(800, 1280), EdgeInsets.only(top: 24, bottom: 48)),
  'big tablet 1024x1366': (Size(1024, 1366), EdgeInsets.only(top: 24, bottom: 20)),
};

const _textScales = [1.0, 1.3];

const _result = LevelResult(
    won: true, stars: 3, score: 12345, moves: 42, mistakes: 0, seconds: 754, bestCombo: 12, arrowsCleared: 42);
const _lost = LevelResult(
    won: false, stars: 0, score: 820, moves: 30, mistakes: 3, seconds: 90, bestCombo: 4, arrowsCleared: 18,
    failReason: FailReason.timeUp);

Map<String, Widget Function()> _screens() => {
      'home': () => const HomeScreen(),
      'level map': () => const LevelMapScreen(),
      'modes': () => const ModesScreen(),
      'daily': () => const DailyChallengeScreen(),
      'shop boosters': () => const ShopScreen(),
      'shop skins': () => const ShopScreen(initialTab: 1),
      'shop themes': () => const ShopScreen(initialTab: 2),
      'shop special': () => const ShopScreen(initialTab: 3),
      'achievements': () => const AchievementsScreen(),
      'settings': () => const SettingsScreen(),
      'profile': () => const ProfileScreen(),
      'game tutorial': () => const GameScreen(launch: GameLaunch.campaign(1)),
      'game expert': () => const GameScreen(launch: GameLaunch.campaign(47)),
      'game timed': () => const GameScreen(launch: GameLaunch(GameMode.timed, 3)),
      'game daily': () => GameScreen(launch: GameLaunch(GameMode.daily, 0, date: DateTime(2026, 11, 15))),
      'game tower': () => const GameScreen(launch: GameLaunch(GameMode.tower, 0)),
      'pause': () => Scaffold(
          body: PauseOverlay(onResume: () {}, onRestart: () {}, onSettings: () {}, onExit: () {})),
      'level complete': () => Scaffold(
          body: LevelCompleteOverlay(
              result: _result,
              reward: const LevelReward(coins: 135, firstClear: true, newBest: true, unlocked: []),
              onNext: () {},
              onReplay: () {},
              onHome: () {})),
      'game over': () => Scaffold(
          body: GameOverOverlay(
              result: _lost, best: 9999, canContinue: true, onRetry: () {}, onContinue: () {}, onHome: () {})),
    };

Future<Widget> _app(Widget Function() screen, double textScale) async {
  final repo = InMemoryProgressRepository();
  final audio = AudioService();
  final haptics = HapticsService();
  final analytics = DebugAnalyticsService();
  final ads = AdMobService(consent: NoConsentService(), analytics: analytics)..adsEnabled = false;
  final services = AppServices(audio: audio, haptics: haptics, analytics: analytics, ads: ads, levels: LevelCatalog());
  final progress = ProgressController(repo, clock: () => DateTime(2026, 11, 15, 19));
  final settings = SettingsController(repo, audio, haptics);
  await progress.load();
  await settings.load();
  progress.applyScreenshotProgress(); // realistic, content-heavy state
  return MultiProvider(
    providers: [
      Provider.value(value: services),
      ChangeNotifierProvider.value(value: progress),
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: ads),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return ArrowFlowApp.clampText(MediaQuery(data: mq.copyWith(textScaler: TextScaler.linear(textScale)), child: child!));
      },
      home: screen(),
    ),
  );
}

void main() {
  for (final MapEntry(key: device, value: (size, padding)) in _devices.entries) {
    for (final scale in _textScales) {
      for (final MapEntry(key: name, value: screen) in _screens().entries) {
        testWidgets('$name fits on $device @ text x$scale', (tester) async {
          tester.view
            ..physicalSize = size * 3
            ..devicePixelRatio = 3
            ..padding = FakeViewPadding(top: padding.top * 3, bottom: padding.bottom * 3)
            ..viewPadding = FakeViewPadding(top: padding.top * 3, bottom: padding.bottom * 3);
          addTearDown(tester.view.reset);

          final overflows = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (details) {
            final text = details.exceptionAsString();
            if (text.contains('overflowed') || text.contains('RenderFlex') || text.contains('BoxConstraints')) {
              final where = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(details.toString())?.group(0) ?? '?';
              overflows.add('${text.split('\n').first} @ $where');
            } else {
              previous?.call(details);
            }
          };
          addTearDown(() => FlutterError.onError = previous);

          await tester.pumpWidget(await _app(screen, scale));
          for (var i = 0; i < 12; i++) {
            await tester.pump(const Duration(milliseconds: 250));
          }
          // Dialog on home: the daily reward popup.
          if (name == 'home') {
            showDailyRewardDialog(tester.element(find.byType(HomeScreen)));
            for (var i = 0; i < 8; i++) {
              await tester.pump(const Duration(milliseconds: 250));
            }
          }
          FlutterError.onError = previous;
          expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));

          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 2));
        });
      }
    }
  }
}
