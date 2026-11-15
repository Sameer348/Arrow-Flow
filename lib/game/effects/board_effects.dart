import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart';

import '../../core/theme/app_colors.dart';
import '../../models/arrow_data.dart';
import '../board/board_layout.dart';
import 'particle_system.dart';

/// Escape animation state for one arrow (spec §26 stages).
class EscapeAnim {
  EscapeAnim(this.arrow, this.distance);
  final ArrowData arrow;

  /// Cells to travel until the tail is off the board.
  final double distance;
  double t = 0;
  bool exitBurstDone = false;
  bool startBurstDone = false;

  static const anticipation = 0.10;
  static const travel = 0.50; // acceleration 150ms + escape ~350ms
  static const total = anticipation + travel;

  bool get done => t >= total + 0.18; // extra time for trail fade

  /// Offset along direction, in cells.
  double get offsetCells {
    if (t < anticipation) {
      final k = t / anticipation;
      return -0.16 * Curves.easeOut.transform(k);
    }
    final k = ((t - anticipation) / travel).clamp(0.0, 1.0);
    final f = k * k * (1.6 - 0.6 * k); // accelerating, exits at speed
    return -0.16 + (distance + 0.16) * f;
  }

  double get scale {
    if (t < anticipation) return 1 + 0.07 * (t / anticipation);
    final k = ((t - anticipation) / 0.12).clamp(0.0, 1.0);
    return 1.07 - 0.07 * k;
  }
}

/// Blocked-tap feedback: bump toward the blocker and bounce back.
class BlockedAnim {
  BlockedAnim(this.arrowId, this.travelCells, this.blockerId);
  final int arrowId;
  final int travelCells;
  final int? blockerId;
  double t = 0;

  double get goTime => 0.08 + 0.035 * travelCells.clamp(0, 6);
  double get total => goTime + 0.2;
  bool get done => t >= total;

  /// Forward offset in cells: slide to just before the blocker, return.
  double get offsetCells {
    final reach = travelCells + 0.14;
    if (t < goTime) return reach * Curves.easeIn.transform(t / goTime);
    final k = ((t - goTime) / 0.2).clamp(0.0, 1.0);
    return reach * (1 - Curves.easeOutBack.transform(k)).clamp(-0.1, 1.0);
  }

  /// 0..1 coral tint intensity.
  double get tint => t < goTime ? 0.4 : (1 - ((t - goTime) / 0.2)).clamp(0.0, 1.0);

  /// Lateral shake on impact, in cells.
  double get shake {
    if (t < goTime) return 0;
    final k = (t - goTime) / 0.2;
    if (k > 1) return 0;
    return 0.05 * (1 - k) * math.sin(k * math.pi * 6);
  }
}

class _Timed {
  _Timed(this.duration);
  final double duration;
  double t = 0;
  double get k => (t / duration).clamp(0.0, 1.0);
  bool get done => t >= duration;
}

class FloatingText {
  FloatingText(this.position, this.painter, this.color);
  final Offset position;
  final TextPainter painter;
  final Color color;
  double t = 0;
  static const life = 0.9;
}

/// Visual-only animation state for the board. The painter reads it; the
/// game screen's Ticker calls [update]. It never changes game state.
class BoardEffects extends ChangeNotifier {
  final particles = ParticleSystem();
  final escapes = <EscapeAnim>[];
  final blocked = <int, BlockedAnim>{};
  final blockerFlash = <int, _Timed>{};
  final appear = <int, _Timed>{};
  final spin = <int, _Timed>{};
  final shatter = <EscapeAnim>[];
  final floats = <FloatingText>[];
  double boardPulse = 0; // seconds remaining
  double clock = 0;
  bool hintActive = false;

  /// Set by the painter each frame so emitters know pixel positions.
  BoardLayout? layout;
  Color accent = AppColors.primary;
  bool sparkleSkin = false;
  bool hammerActive = false;
  bool reduceMotion = false;

  /// Bumped whenever the static (non-animated) arrow layer must be redrawn.
  int staticVersion = 0;
  ui.Picture? staticPicture;
  Object? staticKey;

  void invalidateStatic() {
    staticVersion++;
    staticPicture?.dispose();
    staticPicture = null;
  }

  bool get isAnimating =>
      escapes.isNotEmpty ||
      blocked.isNotEmpty ||
      blockerFlash.isNotEmpty ||
      appear.isNotEmpty ||
      spin.isNotEmpty ||
      shatter.isNotEmpty ||
      floats.isNotEmpty ||
      boardPulse > 0 ||
      particles.hasActive;

  /// Ids drawn by the dynamic layer this frame (excluded from the cache).
  Set<int> get dynamicIds => {...blocked.keys, ...blockerFlash.keys, ...appear.keys, ...spin.keys};

  void addEscape(ArrowData a, double distance) {
    escapes.add(EscapeAnim(a, distance));
    boardPulse = 0.25;
    invalidateStatic();
    notifyListeners();
  }

  void addBlocked(int id, int travelCells, int? blockerId) {
    blocked[id] = BlockedAnim(id, reduceMotion ? 0 : travelCells, blockerId);
    if (blockerId != null) blockerFlash[blockerId] = _Timed(0.45);
    invalidateStatic();
    notifyListeners();
  }

  void addAppear(int id) {
    appear[id] = _Timed(0.3);
    invalidateStatic();
    notifyListeners();
  }

  void addSpin(Iterable<int> ids) {
    for (final id in ids) {
      spin[id] = _Timed(0.42);
    }
    invalidateStatic();
    notifyListeners();
  }

  void addShatter(ArrowData a) {
    shatter.add(EscapeAnim(a, 0));
    boardPulse = 0.3;
    invalidateStatic();
    notifyListeners();
  }

  void addFloat(Offset at, String text, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: color.withValues(alpha: 0.8), blurRadius: 12)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    floats.add(FloatingText(at, tp, color));
    if (floats.length > 4) floats.removeAt(0).painter.dispose();
  }

  /// Advance all animations. Returns true if anything needs a repaint.
  bool update(double dt) {
    clock += dt;
    final animating = isAnimating;
    if (!animating && !hintActive && !hammerActive) return false;

    var staticDirty = false;
    for (final e in escapes) {
      e.t += dt;
      _emitFor(e);
    }
    escapes.removeWhere((e) => e.done);
    for (final s in shatter) {
      s.t += dt;
    }
    shatter.removeWhere((s) => s.t > 0.3);
    staticDirty |= _tickMap<BlockedAnim>(blocked, (a) => (a..t += dt).done);
    staticDirty |= _tickMap<_Timed>(blockerFlash, (a) => (a..t += dt).done);
    staticDirty |= _tickMap<_Timed>(appear, (a) => (a..t += dt).done);
    staticDirty |= _tickMap<_Timed>(spin, (a) => (a..t += dt).done);
    for (final f in floats) {
      f.t += dt;
    }
    floats.removeWhere((f) {
      final dead = f.t >= FloatingText.life;
      if (dead) f.painter.dispose();
      return dead;
    });
    if (boardPulse > 0) boardPulse = (boardPulse - dt).clamp(0, 1);
    particles.update(dt);
    if (staticDirty) invalidateStatic();
    notifyListeners();
    return true;
  }

  void _emitFor(EscapeAnim e) {
    final l = layout;
    if (l == null) return;
    final a = e.arrow;
    final dir = Offset(a.direction.dCol.toDouble(), a.direction.dRow.toDouble());
    if (!e.startBurstDone && e.t >= EscapeAnim.anticipation) {
      e.startBurstDone = true;
      final tail = l.center(a.tail, layer: a.layer) - dir * (l.cell * 0.3);
      particles.directional(tail, -dir, accent, count: 6, speed: 140, spread: 1.2);
    }
    if (!e.exitBurstDone && e.offsetCells >= e.distance - a.length - 0.6) {
      e.exitBurstDone = true;
      final head = l.center(a.head, layer: a.layer) + dir * (e.offsetCells * l.cell);
      particles.directional(head, dir, accent, count: 12, speed: 320);
      particles.burst(head, AppColors.textPrimary, count: 6, speed: 90, size: 2);
      if (sparkleSkin) particles.burst(head, accent, count: 10, speed: 200, size: 2.2, life: 0.7);
    }
  }

  /// Big celebratory burst over the whole board (level complete).
  void celebrate(List<Color> colors) {
    final l = layout;
    if (l == null) return;
    final c = l.grid.center;
    for (var i = 0; i < colors.length; i++) {
      particles.burst(c, colors[i], count: 26, speed: 420, size: 3.4, life: 0.9);
    }
    boardPulse = 0.4;
    notifyListeners();
  }

  void hammerBurst(ArrowData a) {
    final l = layout;
    if (l == null) return;
    for (final cell in a.cells) {
      particles.burst(l.center(cell, layer: a.layer), AppColors.warning, count: 10, speed: 220, size: 3);
    }
  }

  bool _tickMap<T>(Map<int, T> m, bool Function(T) step) {
    final before = m.length;
    m.removeWhere((_, v) => step(v));
    return m.length != before;
  }

  void reset() {
    escapes.clear();
    blocked.clear();
    blockerFlash.clear();
    appear.clear();
    spin.clear();
    shatter.clear();
    for (final f in floats) {
      f.painter.dispose();
    }
    floats.clear();
    particles.clear();
    invalidateStatic();
  }

  @override
  void dispose() {
    for (final f in floats) {
      f.painter.dispose();
    }
    staticPicture?.dispose();
    super.dispose();
  }
}
