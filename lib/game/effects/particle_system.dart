import 'dart:math' as math;
import 'dart:ui';

/// A pooled particle. Fields are mutable to avoid per-frame allocation.
class Particle {
  double x = 0, y = 0, vx = 0, vy = 0;
  double life = 0, maxLife = 1, size = 2;
  Color color = const Color(0xFFFFFFFF);
  bool active = false;
  bool spark = false;
}

/// Fixed-size particle pool. Emitting when full recycles the oldest.
class ParticleSystem {
  ParticleSystem({int capacity = 220}) : _pool = List.generate(capacity, (_) => Particle(), growable: false);

  final List<Particle> _pool;
  final math.Random _rng = math.Random(7);
  int _cursor = 0;
  double intensity = 1; // graphics quality multiplier
  final Paint _paint = Paint()..blendMode = BlendMode.plus;

  bool get hasActive => _pool.any((p) => p.active);

  Particle _next() {
    final p = _pool[_cursor];
    _cursor = (_cursor + 1) % _pool.length;
    return p;
  }

  /// Radial burst.
  void burst(Offset at, Color color, {int count = 14, double speed = 160, double size = 3, double life = 0.45}) {
    final n = (count * intensity).round();
    for (var i = 0; i < n; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final s = speed * (0.35 + _rng.nextDouble() * 0.65);
      _spawn(at, math.cos(a) * s, math.sin(a) * s, color, size * (0.6 + _rng.nextDouble() * 0.6), life * (0.7 + _rng.nextDouble() * 0.5));
    }
  }

  /// Cone of sparks travelling along [dir] (unit vector).
  void directional(Offset at, Offset dir, Color color, {int count = 10, double speed = 260, double spread = 0.6, double size = 2.4}) {
    final base = math.atan2(dir.dy, dir.dx);
    final n = (count * intensity).round();
    for (var i = 0; i < n; i++) {
      final a = base + (_rng.nextDouble() - 0.5) * spread;
      final s = speed * (0.4 + _rng.nextDouble() * 0.6);
      _spawn(at, math.cos(a) * s, math.sin(a) * s, color, size, 0.35 + _rng.nextDouble() * 0.25, spark: true);
    }
  }

  void _spawn(Offset at, double vx, double vy, Color c, double size, double life, {bool spark = false}) {
    final p = _next()
      ..x = at.dx
      ..y = at.dy
      ..vx = vx
      ..vy = vy
      ..color = c
      ..size = size
      ..life = life
      ..maxLife = life
      ..spark = spark
      ..active = true;
    p.active = true;
  }

  void update(double dt) {
    final drag = math.pow(0.9, dt * 60).toDouble();
    for (final p in _pool) {
      if (!p.active) continue;
      p.life -= dt;
      if (p.life <= 0) {
        p.active = false;
        continue;
      }
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= drag;
      p.vy = p.vy * drag + 60 * dt; // gentle gravity
    }
  }

  void paint(Canvas canvas) {
    for (final p in _pool) {
      if (!p.active) continue;
      final t = (p.life / p.maxLife).clamp(0.0, 1.0);
      _paint.color = p.color.withValues(alpha: t * 0.9);
      if (p.spark) {
        _paint
          ..strokeWidth = p.size * t + 0.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(p.x, p.y), Offset(p.x - p.vx * 0.03, p.y - p.vy * 0.03), _paint);
      } else {
        canvas.drawCircle(Offset(p.x, p.y), p.size * (0.4 + 0.6 * t), _paint);
      }
    }
  }

  void clear() {
    for (final p in _pool) {
      p.active = false;
    }
  }
}
