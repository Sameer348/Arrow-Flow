import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'game/levels/level_catalog.dart';
import 'repositories/progress_repository.dart';
import 'services/ads/admob_service.dart';
import 'services/ads/consent_service.dart';
import 'services/analytics/analytics_service.dart';
import 'services/app_services.dart';
import 'services/audio/audio_service.dart';
import 'services/haptics/haptics_service.dart';
import 'state/progress_controller.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0B1020),
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Never show red error screens / stack traces to players in release.
  ErrorWidget.builder = (details) => const _FriendlyError();

  final repo = await LocalProgressRepository.create();
  final audio = AudioService();
  final haptics = HapticsService();
  final analytics = DebugAnalyticsService();
  final ads = AdMobService(consent: UmpConsentService(), analytics: analytics);
  final services = AppServices(audio: audio, haptics: haptics, analytics: analytics, ads: ads, levels: LevelCatalog());

  final progress = ProgressController(repo);
  final settings = SettingsController(repo, audio, haptics);
  await Future.wait([progress.load(), settings.load()]);
  const screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');
  if (screenshotMode) progress.applyScreenshotProgress();
  ads
    ..adsEnabled = progress.progress.adsEnabled
    ..personalized = settings.settings.personalizedAds;

  // Audio + ads initialise in the background; the game is playable
  // immediately and fully offline even if both fail.
  unawaited(audio.init(music: settings.settings.music, sfx: settings.settings.sfx));
  if (!screenshotMode) unawaited(ads.init());

  runApp(MultiProvider(
    providers: [
      Provider.value(value: services),
      ChangeNotifierProvider.value(value: progress),
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: ads),
    ],
    child: const ArrowFlowApp(),
  ));
}

class _FriendlyError extends StatelessWidget {
  const _FriendlyError();

  @override
  Widget build(BuildContext context) => const Center(
        child: Icon(Icons.auto_fix_high_rounded, color: Color(0xFF69758F), size: 28),
      );
}
