enum GraphicsQuality { low, high }

class AppSettings {
  const AppSettings({
    this.music = true,
    this.sfx = true,
    this.haptics = true,
    this.notifications = true,
    this.reduceMotion = false,
    this.showFreeArrows = true,
    this.graphics = GraphicsQuality.high,
    this.personalizedAds = true,
  });

  final bool music;
  final bool sfx;
  final bool haptics;
  final bool notifications;
  final bool reduceMotion;

  /// Subtly brighten arrows that can move right now (accessibility aid).
  final bool showFreeArrows;
  final GraphicsQuality graphics;
  final bool personalizedAds;

  AppSettings copyWith({
    bool? music,
    bool? sfx,
    bool? haptics,
    bool? notifications,
    bool? reduceMotion,
    bool? showFreeArrows,
    GraphicsQuality? graphics,
    bool? personalizedAds,
  }) =>
      AppSettings(
        music: music ?? this.music,
        sfx: sfx ?? this.sfx,
        haptics: haptics ?? this.haptics,
        notifications: notifications ?? this.notifications,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        showFreeArrows: showFreeArrows ?? this.showFreeArrows,
        graphics: graphics ?? this.graphics,
        personalizedAds: personalizedAds ?? this.personalizedAds,
      );

  Map<String, dynamic> toJson() => {
        'music': music,
        'sfx': sfx,
        'haptics': haptics,
        'notifications': notifications,
        'reduceMotion': reduceMotion,
        'showFreeArrows': showFreeArrows,
        'graphics': graphics.name,
        'personalizedAds': personalizedAds,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        music: j['music'] as bool? ?? true,
        sfx: j['sfx'] as bool? ?? true,
        haptics: j['haptics'] as bool? ?? true,
        notifications: j['notifications'] as bool? ?? true,
        reduceMotion: j['reduceMotion'] as bool? ?? false,
        showFreeArrows: j['showFreeArrows'] as bool? ?? true,
        graphics: GraphicsQuality.values.firstWhere((g) => g.name == j['graphics'], orElse: () => GraphicsQuality.high),
        personalizedAds: j['personalizedAds'] as bool? ?? true,
      );
}
