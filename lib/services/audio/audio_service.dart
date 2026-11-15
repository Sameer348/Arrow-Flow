import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum Sfx {
  button('button'),
  tap('tap'),
  escape('escape'),
  blocked('blocked'),
  combo1('combo_1'),
  combo2('combo_2'),
  combo3('combo_3'),
  booster('booster'),
  coin('coin'),
  star('star'),
  levelComplete('level_complete'),
  gameOver('game_over'),
  unlock('unlock');

  const Sfx(this.file);
  final String file;
  String get asset => 'sounds/$file.wav';
}

/// Music + pooled low-latency sound effects. Every call is fire-and-forget
/// and failure-tolerant: audio must never crash or block the game.
class AudioService {
  bool _musicOn = true;
  bool _sfxOn = true;
  bool _ready = false;
  final Map<Sfx, AudioPool> _pools = {};
  AudioPlayer? _music;
  DateTime _lastEscape = DateTime(2000);

  Future<void> init({required bool music, required bool sfx}) async {
    _musicOn = music;
    _sfxOn = sfx;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
      for (final s in Sfx.values) {
        _pools[s] = await AudioPool.createFromAsset(
          path: s.asset,
          maxPlayers: s == Sfx.escape || s == Sfx.tap ? 4 : 2,
          playerMode: PlayerMode.lowLatency,
        );
      }
      _music = AudioPlayer(playerId: 'music');
      await _music!.setReleaseMode(ReleaseMode.loop);
      await _music!.setVolume(0.32);
      _ready = true;
      if (_musicOn) unawaited(_startMusic());
    } on Object catch (e) {
      debugPrint('Audio unavailable: $e');
    }
  }

  Future<void> _startMusic() async {
    try {
      await _music?.play(AssetSource('music/ambient_loop.wav'));
    } on Object catch (e) {
      debugPrint('Music failed: $e');
    }
  }

  void setMusic(bool on) {
    _musicOn = on;
    if (!_ready) return;
    if (on) {
      unawaited(_startMusic());
    } else {
      unawaited(_music?.pause());
    }
  }

  void setSfx(bool on) => _sfxOn = on;

  void play(Sfx s, {double volume = 0.8}) {
    if (!_sfxOn || !_ready) return;
    final pool = _pools[s];
    if (pool == null) return;
    pool.start(volume: volume).catchError((Object e) {
      debugPrint('Sfx $s failed: $e');
      return () async {};
    });
  }

  /// Escape sound; rapid successive escapes get quieter to avoid noise.
  void escape() {
    final now = DateTime.now();
    final close = now.difference(_lastEscape).inMilliseconds < 120;
    _lastEscape = now;
    play(Sfx.escape, volume: close ? 0.45 : 0.75);
  }

  void combo(int multiplier) => play(switch (multiplier) {
        >= 5 => Sfx.combo3,
        >= 3 => Sfx.combo2,
        _ => Sfx.combo1,
      });

  /// Pause music when the app goes to background.
  void onBackground() => unawaited(_music?.pause());
  void onForeground() {
    if (_musicOn && _ready) unawaited(_music?.resume());
  }

  Future<void> dispose() async {
    for (final p in _pools.values) {
      await p.dispose();
    }
    await _music?.dispose();
  }
}
