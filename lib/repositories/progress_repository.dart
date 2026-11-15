import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/player_progress.dart';

/// Persistence abstraction. Swap the implementation (e.g. cloud save)
/// without touching game or UI code.
abstract class ProgressRepository {
  Future<PlayerProgress> loadProgress();
  Future<void> saveProgress(PlayerProgress progress);
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<void> reset();
}

/// Local, offline-first storage backed by SharedPreferences (JSON blobs).
class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository(this._prefs);

  static const _progressKey = 'arrowflow.progress.v1';
  static const _settingsKey = 'arrowflow.settings.v1';
  final SharedPreferences _prefs;

  static Future<LocalProgressRepository> create() async =>
      LocalProgressRepository(await SharedPreferences.getInstance());

  @override
  Future<PlayerProgress> loadProgress() async {
    final raw = _prefs.getString(_progressKey);
    if (raw == null) return PlayerProgress();
    try {
      return PlayerProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Corrupt data should never brick the game.
      return PlayerProgress();
    }
  }

  @override
  Future<void> saveProgress(PlayerProgress progress) =>
      _prefs.setString(_progressKey, jsonEncode(progress.toJson()));

  @override
  Future<AppSettings> loadSettings() async {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return const AppSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) =>
      _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));

  @override
  Future<void> reset() async {
    await _prefs.remove(_progressKey);
  }
}

/// In-memory implementation for tests and previews.
class InMemoryProgressRepository implements ProgressRepository {
  String? _progress;
  AppSettings _settings = const AppSettings();

  @override
  Future<PlayerProgress> loadProgress() async =>
      _progress == null ? PlayerProgress() : PlayerProgress.fromJson(jsonDecode(_progress!) as Map<String, dynamic>);

  @override
  Future<void> saveProgress(PlayerProgress progress) async => _progress = jsonEncode(progress.toJson());

  @override
  Future<AppSettings> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async => _settings = settings;

  @override
  Future<void> reset() async => _progress = null;
}
