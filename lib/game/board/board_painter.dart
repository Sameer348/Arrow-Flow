import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/arrow_data.dart';
import '../../models/cosmetics.dart';
import '../arrows/arrow_renderer.dart';
import '../collision/collision_detector.dart';
import '../effects/board_effects.dart';
import '../engine/game_session.dart';
import 'board_layout.dart';

/// Renders the whole board in one CustomPainter: no per-arrow widgets.
///
/// Arrows that are not animating are recorded once into a cached
/// [ui.Picture] and replayed every frame; only animating arrows, trails and
/// particles are drawn live.
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.session,
    required this.effects,
    required this.theme,
    required this.skin,
    required this.showFree,
    this.extrude = false,
    this.highQuality = true,
  }) : super(repaint: Listenable.merge([session, effects]));

  final GameSession session;
  final BoardEffects effects;
  final GameTheme theme;
  final ArrowSkin skin;
  final bool showFree;
  final bool extrude;
  final bool highQuality;

  static final ArrowRenderer _renderer = ArrowRenderer();
  static final Paint _fill = Paint();
  static final Paint _trail = Paint()
    ..strokeCap = StrokeCap.round
    ..blendMode = BlendMode.plus;

  @override
  void paint(Canvas canvas, Size size) {
    final level = session.level;
    final layout = BoardLayout(size, level.rows, level.cols, layers: level.layerCount);
    effects.layout = layout;
    effects.accent = skin.resolveGlow(theme);
    effects.sparkleSkin = skin.sparkle;
    _renderer.highQuality = highQuality;

    // Board reaction: a tiny breathe after each escape.
    final pulse = effects.boardPulse > 0 ? math.sin(effects.boardPulse / 0.3 * math.pi).abs() * 0.008 : 0.0;
    if (pulse > 0) {
      final c = layout.grid.center;
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..scale(1 + pulse)
        ..translate(-c.dx, -c.dy);
    }

    _paintBoard(canvas, layout);
    _paintStatic(canvas, size, layout);
    _paintDynamic(canvas, layout);
    _paintEscapes(canvas, layout);
    effects.particles.paint(canvas);
    _paintFloats(canvas);

    if (pulse > 0) canvas.restore();
  }

  void _paintBoard(Canvas canvas, BoardLayout l) {
    final r = RRect.fromRectAndRadius(l.boardRect, Radius.circular(l.cell * 0.45));
    // Ambient drop shadow.
    _fill
      ..shader = null
      ..color = const Color(0x66000000)
      ..maskFilter = highQuality ? const MaskFilter.blur(BlurStyle.normal, 18) : null;
    canvas.drawRRect(r.shift(const Offset(0, 10)), _fill);
    _fill.maskFilter = null;
    // Surface gradient.
    _fill.shader = ui.Gradient.linear(l.boardRect.topCenter, l.boardRect.bottomCenter, [theme.boardTop, theme.boardBottom]);
    canvas.drawRRect(r, _fill);
    _fill.shader = null;
    // Ambient light from top-left.
    _fill.shader = ui.Gradient.radial(
      l.boardRect.topLeft + Offset(l.boardRect.width * 0.25, 0),
      l.boardRect.longestSide * 0.8,
      [Colors.white.withValues(alpha: 0.06), Colors.white.withValues(alpha: 0)],
    );
    canvas.drawRRect(r, _fill);
    _fill.shader = null;
    // Inner edge highlight / shadow (fake inner shadow).
    _fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = ui.Gradient.linear(l.boardRect.topCenter, l.boardRect.bottomCenter,
          [Colors.white.withValues(alpha: 0.10), Colors.black.withValues(alpha: 0.25)]);
    canvas.drawRRect(r.deflate(0.6), _fill);
    _fill
      ..style = PaintingStyle.fill
      ..shader = null;

    // Cells of the board shape.
    _fill.color = theme.cell;
    final inset = l.cell * 0.08;
    final rad = Radius.circular(l.cell * 0.18);
    for (final c in session.level.mask) {
      final rect = Rect.fromLTWH(l.origin.dx + c.col * l.cell + inset, l.origin.dy + c.row * l.cell + inset,
          l.cell - inset * 2, l.cell - inset * 2);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, rad), _fill);
    }
  }

  void _paintStatic(Canvas canvas, Size size, BoardLayout l) {
    final dyn = effects.dynamicIds;
    final hint = session.hintArrowId;
    final key = Object.hash(effects.staticVersion, size, theme.id, skin.id, showFree, hint, extrude, highQuality);
    if (effects.staticPicture == null || effects.staticKey != key) {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final arrows = session.board.arrows.toList()..sort((a, b) => a.layer - b.layer);
      for (final a in arrows) {
        if (dyn.contains(a.id) || a.id == hint) continue;
        _drawArrow(c, l, a);
      }
      effects.staticPicture?.dispose();
      effects.staticPicture = rec.endRecording();
      effects.staticKey = key;
    }
    canvas.drawPicture(effects.staticPicture!);
  }

  void _drawArrow(Canvas c, BoardLayout l, ArrowData a,
      {double offsetCells = 0, double lateral = 0, double alpha = 1, double scale = 1, double rotation = 0,
      double glow = -1, Color? tint, double tintAmount = 0, double outline = 0, Color outlineColor = AppColors.error}) {
    final check = CollisionDetector.check(session.board, a);
    final free = check.canMove;
    final covered = check.reason == BlockReason.covered;
    final dir = Offset(a.direction.dCol.toDouble(), a.direction.dRow.toDouble());
    final perp = Offset(-dir.dy, dir.dx);
    final colors = a.type == ArrowType.bonus
        ? const [AppColors.violet, AppColors.primary]
        : skin.resolveColors(theme);
    final emphasise = showFree && session.mode.allowsFreeHighlight;
    _renderer.draw(
      c,
      head: l.center(a.head, layer: a.layer) + dir * (offsetCells * l.cell) + perp * (lateral * l.cell),
      direction: a.direction,
      length: a.length,
      cell: l.cell,
      colors: colors,
      glowColor: skin.resolveGlow(theme),
      glow: glow >= 0 ? glow : (emphasise && free ? 0.35 : 0),
      alpha: alpha * (covered ? 0.45 : 1),
      scale: scale,
      rotation: rotation,
      desaturate: emphasise && !free ? 0.42 : (covered ? 0.5 : 0),
      tint: tint,
      tintAmount: tintAmount,
      extrude: (extrude || a.layer > 0) ? l.cell * (0.10 + a.layer * 0.04) : 0,
      outline: outline,
      outlineColor: outlineColor,
    );
  }

  void _paintDynamic(Canvas canvas, BoardLayout l) {
    final ordered = session.board.arrows.toList()..sort((a, b) => a.layer - b.layer);
    for (final a in ordered) {
      final id = a.id;
      final b = effects.blocked[id];
      final flash = effects.blockerFlash[id];
      final ap = effects.appear[id];
      final sp = effects.spin[id];
      final isHint = session.hintArrowId == id;
      if (b == null && flash == null && ap == null && sp == null && !isHint) continue;
      var offset = 0.0, lateral = 0.0, alpha = 1.0, scale = 1.0, rotation = 0.0, glow = -1.0, tintAmt = 0.0, outline = 0.0;
      Color? tint;
      if (b != null) {
        offset = b.offsetCells;
        lateral = b.shake;
        tint = AppColors.error;
        tintAmt = b.tint * 0.75;
      }
      if (flash != null) {
        final k = flash.k;
        outline = math.sin(k * math.pi * 3).abs() * (1 - k);
      }
      if (ap != null) {
        final k = Curves.easeOutBack.transform(ap.k);
        alpha = ap.k;
        scale = 0.6 + 0.4 * k;
        tint = Colors.white;
        tintAmt = (1 - ap.k) * 0.8;
        glow = 0.6 * (1 - ap.k);
      }
      if (sp != null) {
        rotation = math.pi * (1 - Curves.easeInOutCubic.transform(sp.k));
        glow = 0.5 * (1 - sp.k);
      }
      if (isHint) {
        final w = 0.5 + 0.5 * math.sin(effects.clock * 6);
        glow = 0.6 + 0.6 * w;
        offset += 0.10 * math.max(0, math.sin(effects.clock * 5));
        tint ??= Colors.white;
        tintAmt = math.max(tintAmt, 0.25 * w);
      }
      _drawArrow(canvas, l, a,
          offsetCells: offset,
          lateral: lateral,
          alpha: alpha,
          scale: scale,
          rotation: rotation,
          glow: glow,
          tint: tint,
          tintAmount: tintAmt,
          outline: outline);
    }
  }

  void _paintEscapes(Canvas canvas, BoardLayout l) {
    final colors = skin.resolveColors(theme);
    for (final e in effects.escapes) {
      final a = e.arrow;
      final dir = Offset(a.direction.dCol.toDouble(), a.direction.dRow.toDouble());
      final off = e.offsetCells;
      final startTail = l.center(a.tail, layer: a.layer);
      final head = l.center(a.head, layer: a.layer) + dir * (off * l.cell);
      final tail = head - dir * ((a.length - 1) * l.cell);

      // Trail: glowing streak from where it started to its tail.
      final travelK = ((e.t - EscapeAnim.anticipation) / EscapeAnim.travel).clamp(0.0, 1.0);
      final fade = e.t > EscapeAnim.total ? 1 - ((e.t - EscapeAnim.total) / 0.18).clamp(0.0, 1.0) : 1.0;
      if (travelK > 0 && fade > 0) {
        final trailStart = startTail + dir * (travelK * travelK * (e.distance * 0.6) * l.cell);
        _trail
          ..strokeWidth = l.cell * 0.22
          ..shader = ui.Gradient.linear(trailStart, tail, [
            colors.first.withValues(alpha: 0),
            colors.last.withValues(alpha: 0.55 * fade),
          ])
          ..maskFilter = highQuality ? MaskFilter.blur(BlurStyle.normal, l.cell * 0.06) : null;
        canvas.drawLine(trailStart, tail, _trail);
        _trail.shader = null;
      }

      final beyond = off - (e.distance - a.length - 0.6);
      final alpha = (1 - (beyond / (a.length + 0.6)).clamp(0.0, 1.0) * 0.9) * (e.t > EscapeAnim.total ? 0 : 1);
      _renderer.draw(
        canvas,
        head: head,
        direction: a.direction,
        length: a.length,
        cell: l.cell,
        colors: a.type == ArrowType.bonus ? const [AppColors.violet, AppColors.primary] : colors,
        glowColor: skin.resolveGlow(theme),
        glow: 0.7,
        alpha: alpha,
        scale: e.scale,
        tint: Colors.white,
        tintAmount: e.t < EscapeAnim.anticipation ? 0.35 : 0.1,
        extrude: extrude || a.layer > 0 ? l.cell * 0.1 : 0,
      );
    }

    for (final s in effects.shatter) {
      final a = s.arrow;
      final k = (s.t / 0.3).clamp(0.0, 1.0);
      _renderer.draw(
        canvas,
        head: l.center(a.head, layer: a.layer),
        direction: a.direction,
        length: a.length,
        cell: l.cell,
        colors: const [AppColors.warning, AppColors.error],
        alpha: 1 - k,
        scale: 1 + k * 0.3,
        glow: 1 - k,
        glowColor: AppColors.warning,
      );
    }
  }

  void _paintFloats(Canvas canvas) {
    for (final f in effects.floats) {
      final k = (f.t / FloatingText.life).clamp(0.0, 1.0);
      final a = 1 - k * k;
      final y = -48 * Curves.easeOut.transform(k);
      final tp = f.painter;
      final pos = f.position + Offset(-tp.width / 2, y - tp.height / 2);
      canvas.saveLayer(pos & tp.size, Paint()..color = Color.fromRGBO(0, 0, 0, a));
      tp.paint(canvas, pos);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.session != session ||
      old.theme != theme ||
      old.skin != skin ||
      old.showFree != showFree ||
      old.extrude != extrude ||
      old.highQuality != highQuality;
}
