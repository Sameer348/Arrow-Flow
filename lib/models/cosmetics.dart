import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum CosmeticRarity {
  common('Common', AppColors.textSecondary),
  rare('Rare', AppColors.primary),
  epic('Epic', AppColors.violet),
  legendary('Legendary', AppColors.warning);

  const CosmeticRarity(this.label, this.color);
  final String label;
  final Color color;
}

/// Purely cosmetic arrow appearance. No gameplay effect.
class ArrowSkin {
  const ArrowSkin({
    required this.id,
    required this.name,
    required this.price,
    this.colors,
    this.glow,
    this.rarity = CosmeticRarity.common,
    this.sparkle = false,
  });

  final String id;
  final String name;
  final int price;

  /// Gradient tail → tip. Null = use the active theme's arrow colours.
  final List<Color>? colors;
  final Color? glow;
  final CosmeticRarity rarity;

  /// Adds extra glitter particles on escape.
  final bool sparkle;

  List<Color> resolveColors(GameTheme theme) => colors ?? [theme.arrowStart, theme.arrowEnd];
  Color resolveGlow(GameTheme theme) => glow ?? resolveColors(theme).first;

  static const classic = ArrowSkin(id: 'classic', name: 'Classic', price: 0);

  static const all = <ArrowSkin>[
    classic,
    ArrowSkin(id: 'crystal', name: 'Crystal', price: 300, rarity: CosmeticRarity.rare, sparkle: true,
        colors: [Color(0xFFE6FBFF), Color(0xFF9ADFFF)], glow: Color(0xFFBFF3FF)),
    ArrowSkin(id: 'neon', name: 'Neon', price: 400, rarity: CosmeticRarity.rare,
        colors: [Color(0xFF39FF9E), Color(0xFF00D9FF)]),
    ArrowSkin(id: 'fire', name: 'Fire', price: 600, rarity: CosmeticRarity.epic,
        colors: [Color(0xFFFF6A4D), Color(0xFFFFB347)]),
    ArrowSkin(id: 'ice', name: 'Ice', price: 600, rarity: CosmeticRarity.epic,
        colors: [Color(0xFF7EE7FF), Color(0xFF7AA7FF)]),
    ArrowSkin(id: 'shadow', name: 'Shadow', price: 700, rarity: CosmeticRarity.epic,
        colors: [Color(0xFF66779C), Color(0xFF3A4566)], glow: Color(0xFF9B6CFF)),
    ArrowSkin(id: 'galaxy', name: 'Galaxy', price: 900, rarity: CosmeticRarity.epic, sparkle: true,
        colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)]),
    ArrowSkin(id: 'cyber', name: 'Cyber', price: 1000, rarity: CosmeticRarity.epic,
        colors: [Color(0xFFFF3CAC), Color(0xFF2B86C5)]),
    ArrowSkin(id: 'gold', name: 'Gold', price: 1500, rarity: CosmeticRarity.legendary, sparkle: true,
        colors: [Color(0xFFFFD76A), Color(0xFFFF9F43)]),
    ArrowSkin(id: 'rainbow', name: 'Rainbow', price: 2000, rarity: CosmeticRarity.legendary, sparkle: true,
        colors: [Color(0xFFFF6B8B), Color(0xFFFFC75F), Color(0xFF35E0A1), Color(0xFF42E8FF), Color(0xFF9B6CFF)]),
  ];

  static ArrowSkin byId(String id) => all.firstWhere((s) => s.id == id, orElse: () => classic);
}

/// Board/background palette. Changes background, board, arrows, particles.
class GameTheme {
  const GameTheme({
    required this.id,
    required this.name,
    required this.price,
    required this.background,
    required this.boardTop,
    required this.boardBottom,
    required this.arrowStart,
    required this.arrowEnd,
    required this.accent,
    this.cell = AppColors.boardCell,
    this.rarity = CosmeticRarity.common,
  });

  final String id;
  final String name;
  final int price;
  final List<Color> background;
  final Color boardTop;
  final Color boardBottom;
  final Color arrowStart;
  final Color arrowEnd;
  final Color accent;
  final Color cell;
  final CosmeticRarity rarity;

  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: background,
      );

  static const midnight = GameTheme(
    id: 'midnight',
    name: 'Midnight',
    price: 0,
    background: [Color(0xFF0E1530), AppColors.background, Color(0xFF080C18)],
    boardTop: AppColors.boardTop,
    boardBottom: AppColors.boardBottom,
    arrowStart: AppColors.primary,
    arrowEnd: AppColors.secondary,
    accent: AppColors.primary,
  );

  static const all = <GameTheme>[
    midnight,
    GameTheme(id: 'ocean', name: 'Ocean', price: 400, rarity: CosmeticRarity.rare,
        background: [Color(0xFF062235), Color(0xFF071A2A), Color(0xFF04111C)],
        boardTop: Color(0xFF0D3047), boardBottom: Color(0xFF0A2234),
        arrowStart: Color(0xFF5CF2E0), arrowEnd: Color(0xFF2F9BFF), accent: Color(0xFF5CF2E0)),
    GameTheme(id: 'aurora', name: 'Aurora', price: 600, rarity: CosmeticRarity.epic,
        background: [Color(0xFF0B1F2A), Color(0xFF0E1428), Color(0xFF130C26)],
        boardTop: Color(0xFF162A3C), boardBottom: Color(0xFF151A33),
        arrowStart: Color(0xFF6CFFB8), arrowEnd: Color(0xFF9B6CFF), accent: Color(0xFF6CFFB8)),
    GameTheme(id: 'candy', name: 'Candy', price: 500, rarity: CosmeticRarity.rare,
        background: [Color(0xFF2A1030), Color(0xFF1F0E28), Color(0xFF150A1E)],
        boardTop: Color(0xFF3A1C44), boardBottom: Color(0xFF2A1534),
        arrowStart: Color(0xFFFF8FD8), arrowEnd: Color(0xFFFFC27A), accent: Color(0xFFFF8FD8)),
    GameTheme(id: 'galaxy', name: 'Galaxy', price: 900, rarity: CosmeticRarity.epic,
        background: [Color(0xFF1A0F3A), Color(0xFF0D0B24), Color(0xFF05040F)],
        boardTop: Color(0xFF231A4A), boardBottom: Color(0xFF161135),
        arrowStart: Color(0xFF8B5CF6), arrowEnd: Color(0xFF22D3EE), accent: Color(0xFFC084FC)),
    GameTheme(id: 'sunset', name: 'Sunset', price: 600, rarity: CosmeticRarity.rare,
        background: [Color(0xFF2E1424), Color(0xFF1E1026), Color(0xFF110A1A)],
        boardTop: Color(0xFF3A1D33), boardBottom: Color(0xFF2A1628),
        arrowStart: Color(0xFFFFB86B), arrowEnd: Color(0xFFFF5C7A), accent: Color(0xFFFFB86B)),
    GameTheme(id: 'forest', name: 'Forest', price: 500, rarity: CosmeticRarity.rare,
        background: [Color(0xFF0B2118), Color(0xFF0A1913), Color(0xFF06100C)],
        boardTop: Color(0xFF143326), boardBottom: Color(0xFF0F261C),
        arrowStart: Color(0xFFB6F36B), arrowEnd: Color(0xFF35E0A1), accent: Color(0xFFB6F36B)),
    GameTheme(id: 'minimal', name: 'Minimal', price: 300,
        background: [Color(0xFF16181D), Color(0xFF121418), Color(0xFF0C0D10)],
        boardTop: Color(0xFF20232A), boardBottom: Color(0xFF1A1C22),
        arrowStart: Color(0xFFF2F4F8), arrowEnd: Color(0xFFB9C0CC), accent: Color(0xFFF2F4F8)),
    GameTheme(id: 'cyber', name: 'Cyber', price: 1000, rarity: CosmeticRarity.legendary,
        background: [Color(0xFF1B0A2E), Color(0xFF0C0A1F), Color(0xFF020611)],
        boardTop: Color(0xFF1E1440), boardBottom: Color(0xFF120E2C),
        arrowStart: Color(0xFFFF3CAC), arrowEnd: Color(0xFF42E8FF), accent: Color(0xFFFF3CAC),
        cell: Color(0x1442E8FF)),
  ];

  static GameTheme byId(String id) => all.firstWhere((t) => t.id == id, orElse: () => midnight);
}
