import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/transitions.dart';
import '../../game/levels/level_catalog.dart';
import '../../models/cosmetics.dart';
import '../../state/progress_controller.dart';
import '../../widgets/badges.dart';
import '../../widgets/pressable.dart';
import '../../widgets/screen_scaffold.dart';
import '../gameplay/game_launch.dart';
import '../gameplay/game_screen.dart';

/// Winding, lazily-built level path that scales to 1000+ levels.
/// Level 1 is at the bottom; the path climbs upward.
class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  static const rowHeight = 104.0;
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final current = context.progress.progress.unlockedLevel;
    // Reverse list: offset 0 == level 1 at the bottom.
    _scroll = ScrollController(initialScrollOffset: math.max(0, (current - 3) * rowHeight));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Horizontal position (0..1) of a node — a gentle sine wave.
  static double nodeX(int level) => 0.5 + 0.28 * math.sin(level * 0.9);

  static String chapterName(int level) {
    final names = GameTheme.all.map((t) => t.name).toList();
    return 'Chapter ${(level - 1) ~/ 25 + 1} · ${names[((level - 1) ~/ 25) % names.length]}';
  }

  void _open(int level) {
    final progress = context.progress;
    if (!progress.isUnlocked(level)) {
      context.services.haptics.subtle();
      context.toast('Finish level ${progress.progress.unlockedLevel} to unlock this one.', icon: Icons.lock_rounded, color: AppColors.textSecondary);
      return;
    }
    Navigator.of(context).push(Transitions.zoom(GameScreen(launch: GameLaunch.campaign(level))));
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final current = progress.progress.unlockedLevel;
    return ScreenScaffold(
      title: 'Level Map',
      showBanner: true,
      child: LayoutBuilder(builder: (context, c) {
        return ListView.builder(
          controller: _scroll,
          reverse: true,
          itemExtent: rowHeight,
          itemCount: LevelCatalog.campaignLength,
          padding: const EdgeInsets.symmetric(vertical: 24),
          itemBuilder: (context, i) {
            final level = i + 1;
            return _LevelRow(
              level: level,
              width: c.maxWidth,
              stars: progress.starsFor(level),
              state: level < current
                  ? _NodeState.done
                  : level == current
                      ? _NodeState.current
                      : _NodeState.locked,
              chapter: (level - 1) % 25 == 0 ? chapterName(level) : null,
              onTap: () => _open(level),
            );
          },
        );
      }),
    );
  }
}

enum _NodeState { done, current, locked }

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.level, required this.width, required this.stars, required this.state, required this.onTap, this.chapter});
  final int level;
  final double width;
  final int stars;
  final _NodeState state;
  final VoidCallback onTap;
  final String? chapter;

  @override
  Widget build(BuildContext context) {
    final x = _LevelMapScreenState.nodeX(level) * width;
    return Stack(clipBehavior: Clip.none, children: [
      // Path to the next node (drawn upward because the list is reversed).
      Positioned.fill(
        child: CustomPaint(
          painter: _PathPainter(
            from: Offset(x, _LevelMapScreenState.rowHeight / 2),
            to: Offset(_LevelMapScreenState.nodeX(level + 1) * width, -_LevelMapScreenState.rowHeight / 2),
            lit: state == _NodeState.done,
          ),
        ),
      ),
      if (chapter != null)
        Positioned(
          left: 16,
          top: 4,
          child: TagChip(label: chapter!, color: AppColors.violet, icon: Icons.auto_awesome_mosaic_rounded),
        ),
      Positioned(left: x - 36, top: _LevelMapScreenState.rowHeight / 2 - 36, child: _LevelNode(level: level, stars: stars, state: state, onTap: onTap)),
    ]);
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({required this.from, required this.to, required this.lit});
  final Offset from;
  final Offset to;
  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = (from.dy + to.dy) / 2;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(from.dx, mid, to.dx, mid, to.dx, to.dy);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6
      ..color = lit ? AppColors.primary.withValues(alpha: 0.55) : AppColors.surfaceElevated;
    if (lit) {
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..color = AppColors.primary.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.from != from || old.to != to || old.lit != lit;
}

class _LevelNode extends StatefulWidget {
  const _LevelNode({required this.level, required this.stars, required this.state, required this.onTap});
  final int level;
  final int stars;
  final _NodeState state;
  final VoidCallback onTap;

  @override
  State<_LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<_LevelNode> with TickerProviderStateMixin {
  AnimationController? _pulse;
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(_LevelNode old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _syncPulse();
  }

  void _syncPulse() {
    if (widget.state == _NodeState.current) {
      _pulse ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
    } else {
      _pulse?.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final node = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: switch (s) {
          _NodeState.current => AppGradients.primary,
          _NodeState.done => AppGradients.surface,
          _NodeState.locked => null,
        },
        color: s == _NodeState.locked ? AppColors.backgroundSecondary : null,
        border: Border.all(
          color: switch (s) {
            _NodeState.done => AppColors.primary.withValues(alpha: 0.6),
            _NodeState.current => Colors.white.withValues(alpha: 0.5),
            _NodeState.locked => AppColors.glassBorder,
          },
          width: 2,
        ),
        boxShadow: [
          const BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 6)),
          if (s == _NodeState.done) BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 16),
        ],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (s == _NodeState.locked)
          const Icon(Icons.lock_rounded, color: AppColors.textDisabled, size: 22)
        else
          Text('${widget.level}', style: AppTextStyles.heading.copyWith(color: s == _NodeState.current ? AppColors.background : AppColors.textPrimary)),
        if (s == _NodeState.done) StarRow(stars: widget.stars, size: 13, spacing: 0),
      ]),
    );

    return Pressable(
      onTap: () {
        if (s == _NodeState.locked) _shake.forward(from: 0);
        widget.onTap();
      },
      feedback: s != _NodeState.locked,
      semanticLabel: 'Level ${widget.level}${s == _NodeState.locked ? ', locked' : ''}',
      child: AnimatedBuilder(
        animation: Listenable.merge([_shake, ?_pulse]),
        builder: (_, child) {
          final dx = math.sin(_shake.value * math.pi * 6) * 6 * (1 - _shake.value);
          final p = _pulse?.value ?? 0;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
              if (_pulse != null)
                Container(
                  width: 72 + 30 * p,
                  height: 72 + 30 * p,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.6 * (1 - p)), width: 2),
                  ),
                ),
              child!,
            ]),
          );
        },
        child: node,
      ),
    );
  }
}
