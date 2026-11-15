import 'booster.dart';

/// Lifetime statistics used by achievements and the profile screen.
class PlayerStats {
  PlayerStats({
    this.levelsCompleted = 0,
    this.arrowsCleared = 0,
    this.perfectLevels = 0,
    this.bestCombo = 0,
    this.fastestSeconds = 0,
    this.dailyCompleted = 0,
    this.dailyStreak = 0,
    this.endlessBest = 0,
    this.towerCompleted = 0,
    this.totalScore = 0,
    this.lastDailyKey,
  });

  int levelsCompleted;
  int arrowsCleared;
  int perfectLevels;
  int bestCombo;
  int fastestSeconds;
  int dailyCompleted;
  int dailyStreak;
  int endlessBest;
  int towerCompleted;
  int totalScore;
  String? lastDailyKey;

  Map<String, dynamic> toJson() => {
        'levelsCompleted': levelsCompleted,
        'arrowsCleared': arrowsCleared,
        'perfectLevels': perfectLevels,
        'bestCombo': bestCombo,
        'fastestSeconds': fastestSeconds,
        'dailyCompleted': dailyCompleted,
        'dailyStreak': dailyStreak,
        'endlessBest': endlessBest,
        'towerCompleted': towerCompleted,
        'totalScore': totalScore,
        'lastDailyKey': lastDailyKey,
      };

  factory PlayerStats.fromJson(Map<String, dynamic> j) => PlayerStats(
        levelsCompleted: j['levelsCompleted'] as int? ?? 0,
        arrowsCleared: j['arrowsCleared'] as int? ?? 0,
        perfectLevels: j['perfectLevels'] as int? ?? 0,
        bestCombo: j['bestCombo'] as int? ?? 0,
        fastestSeconds: j['fastestSeconds'] as int? ?? 0,
        dailyCompleted: j['dailyCompleted'] as int? ?? 0,
        dailyStreak: j['dailyStreak'] as int? ?? 0,
        endlessBest: j['endlessBest'] as int? ?? 0,
        towerCompleted: j['towerCompleted'] as int? ?? 0,
        totalScore: j['totalScore'] as int? ?? 0,
        lastDailyKey: j['lastDailyKey'] as String?,
      );
}

/// Result stored for one daily challenge date.
class DailyResult {
  const DailyResult({required this.score, required this.stars, required this.seconds});
  final int score;
  final int stars;
  final int seconds;

  Map<String, dynamic> toJson() => {'score': score, 'stars': stars, 'seconds': seconds};
  factory DailyResult.fromJson(Map<String, dynamic> j) =>
      DailyResult(score: j['score'] as int, stars: j['stars'] as int, seconds: j['seconds'] as int);
}

/// Everything persisted about the player.
class PlayerProgress {
  PlayerProgress({
    this.unlockedLevel = 1,
    Map<int, int>? stars,
    Map<int, int>? bestScores,
    this.coins = 150,
    Map<Booster, int>? boosters,
    Set<String>? ownedSkins,
    this.selectedSkin = 'classic',
    Set<String>? ownedThemes,
    this.selectedTheme = 'midnight',
    Set<String>? achievements,
    PlayerStats? stats,
    this.dailyRewardDay = 0,
    this.lastRewardClaimKey,
    Map<String, DailyResult>? dailyResults,
    this.tutorialDone = false,
    this.playerName = 'Player',
    this.avatar = 0,
    this.adsEnabled = true,
    this.endlessIndex = 0,
    this.towerIndex = 0,
    Map<String, int>? modeIndex,
  })  : modeIndex = modeIndex ?? {},
        stars = stars ?? {},
        bestScores = bestScores ?? {},
        boosters = boosters ?? {Booster.hint: 3, Booster.undo: 3, Booster.hammer: 1, Booster.shuffle: 1, Booster.freeze: 1, Booster.extraMoves: 1},
        ownedSkins = ownedSkins ?? {'classic'},
        ownedThemes = ownedThemes ?? {'midnight'},
        achievements = achievements ?? {},
        stats = stats ?? PlayerStats(),
        dailyResults = dailyResults ?? {};

  /// Highest level the player may play.
  int unlockedLevel;
  final Map<int, int> stars;
  final Map<int, int> bestScores;
  int coins;
  final Map<Booster, int> boosters;
  final Set<String> ownedSkins;
  String selectedSkin;
  final Set<String> ownedThemes;
  String selectedTheme;
  final Set<String> achievements;
  final PlayerStats stats;

  /// Index (0–6) of the next daily reward in the 7-day cycle.
  int dailyRewardDay;
  String? lastRewardClaimKey;
  final Map<String, DailyResult> dailyResults;
  bool tutorialDone;
  String playerName;
  int avatar;

  /// False once "Remove Ads" is purchased (non-rewarded ads disabled).
  bool adsEnabled;
  int endlessIndex;
  int towerIndex;

  /// Next puzzle index for Timed / Limited / Perfect modes.
  final Map<String, int> modeIndex;

  int get totalStars => stars.values.fold(0, (a, b) => a + b);

  /// Player level derived from total score — 1500 points per level, rising.
  int get playerLevel {
    var lvl = 1;
    var need = 1500;
    var s = stats.totalScore;
    while (s >= need) {
      s -= need;
      lvl++;
      need = (need * 1.15).round();
    }
    return lvl;
  }

  Map<String, dynamic> toJson() => {
        'v': 1,
        'unlockedLevel': unlockedLevel,
        'stars': stars.map((k, v) => MapEntry('$k', v)),
        'bestScores': bestScores.map((k, v) => MapEntry('$k', v)),
        'coins': coins,
        'boosters': boosters.map((k, v) => MapEntry(k.name, v)),
        'ownedSkins': ownedSkins.toList(),
        'selectedSkin': selectedSkin,
        'ownedThemes': ownedThemes.toList(),
        'selectedTheme': selectedTheme,
        'achievements': achievements.toList(),
        'stats': stats.toJson(),
        'dailyRewardDay': dailyRewardDay,
        'lastRewardClaimKey': lastRewardClaimKey,
        'dailyResults': dailyResults.map((k, v) => MapEntry(k, v.toJson())),
        'tutorialDone': tutorialDone,
        'playerName': playerName,
        'avatar': avatar,
        'adsEnabled': adsEnabled,
        'endlessIndex': endlessIndex,
        'towerIndex': towerIndex,
        'modeIndex': modeIndex,
      };

  factory PlayerProgress.fromJson(Map<String, dynamic> j) {
    Map<int, int> intMap(Object? o) =>
        (o as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(int.parse(k), v as int));
    final boosterJson = j['boosters'] as Map<String, dynamic>?;
    return PlayerProgress(
      unlockedLevel: j['unlockedLevel'] as int? ?? 1,
      stars: intMap(j['stars']),
      bestScores: intMap(j['bestScores']),
      coins: j['coins'] as int? ?? 0,
      boosters: boosterJson == null
          ? null
          : {
              for (final b in Booster.values) b: boosterJson[b.name] as int? ?? 0,
            },
      ownedSkins: {...(j['ownedSkins'] as List? ?? ['classic']).cast<String>()},
      selectedSkin: j['selectedSkin'] as String? ?? 'classic',
      ownedThemes: {...(j['ownedThemes'] as List? ?? ['midnight']).cast<String>()},
      selectedTheme: j['selectedTheme'] as String? ?? 'midnight',
      achievements: {...(j['achievements'] as List? ?? const []).cast<String>()},
      stats: j['stats'] == null ? null : PlayerStats.fromJson(j['stats'] as Map<String, dynamic>),
      dailyRewardDay: j['dailyRewardDay'] as int? ?? 0,
      lastRewardClaimKey: j['lastRewardClaimKey'] as String?,
      dailyResults: (j['dailyResults'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, DailyResult.fromJson(v as Map<String, dynamic>))),
      tutorialDone: j['tutorialDone'] as bool? ?? false,
      playerName: j['playerName'] as String? ?? 'Player',
      avatar: j['avatar'] as int? ?? 0,
      adsEnabled: j['adsEnabled'] as bool? ?? true,
      endlessIndex: j['endlessIndex'] as int? ?? 0,
      towerIndex: j['towerIndex'] as int? ?? 0,
      modeIndex: (j['modeIndex'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, v as int)),
    );
  }
}
