/// Platform-independent deterministic PRNG (mulberry32).
///
/// `dart:math` Random is deterministic per platform but not guaranteed to
/// match between the VM and web, so level generation uses this instead:
/// the same seed always yields the same level everywhere.
class SeededRandom {
  SeededRandom(int seed) : _state = seed & 0xFFFFFFFF;

  int _state;

  /// Next unsigned 32-bit integer.
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = _imul(t ^ (t >>> 15), t | 1);
    t ^= (t + _imul(t ^ (t >>> 7), t | 61)) & 0xFFFFFFFF;
    return (t ^ (t >>> 14)) & 0xFFFFFFFF;
  }

  /// Uniform int in [0, max).
  int nextInt(int max) {
    assert(max > 0);
    return nextUint32() % max;
  }

  /// Uniform double in [0, 1).
  double nextDouble() => nextUint32() / 4294967296.0;

  bool nextBool([double chance = 0.5]) => nextDouble() < chance;

  T pick<T>(List<T> items) => items[nextInt(items.length)];

  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }

  static int _imul(int a, int b) {
    final aHi = (a >>> 16) & 0xFFFF;
    final aLo = a & 0xFFFF;
    final bHi = (b >>> 16) & 0xFFFF;
    final bLo = b & 0xFFFF;
    return ((aLo * bLo) + ((((aHi * bLo) + (aLo * bHi)) << 16) & 0xFFFFFFFF)) & 0xFFFFFFFF;
  }

  /// Stable 32-bit FNV-1a hash of a string (used for date seeds).
  static int hashString(String s) {
    var h = 0x811C9DC5;
    for (final unit in s.codeUnits) {
      h ^= unit;
      h = _imul(h, 0x01000193);
    }
    return h & 0xFFFFFFFF;
  }
}
