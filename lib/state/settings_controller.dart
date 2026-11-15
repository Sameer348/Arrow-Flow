import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../repositories/progress_repository.dart';
import '../services/audio/audio_service.dart';
import '../services/haptics/haptics_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._repo, this._audio, this._haptics);

  final ProgressRepository _repo;
  final AudioService _audio;
  final HapticsService _haptics;
  AppSettings _s = const AppSettings();

  AppSettings get settings => _s;

  Future<void> load() async {
    _s = await _repo.loadSettings();
    _haptics.enabled = _s.haptics;
    notifyListeners();
  }

  void update(AppSettings next) {
    if (next.music != _s.music) _audio.setMusic(next.music);
    if (next.sfx != _s.sfx) _audio.setSfx(next.sfx);
    _haptics.enabled = next.haptics;
    _s = next;
    notifyListeners();
    unawaited(_repo.saveSettings(next));
  }
}
