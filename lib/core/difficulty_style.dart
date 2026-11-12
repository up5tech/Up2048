import 'package:flutter/material.dart';

import '../domain/models/difficulty.dart';

/// Per-difficulty accent colour and one-line description (PLAN.md §3.3, §13.3).
class DifficultyStyle {
  final Color accent;
  final String tagline;
  const DifficultyStyle({required this.accent, required this.tagline});
}

const Map<Difficulty, DifficultyStyle> kDifficultyStyles = {
  Difficulty.easy: DifficultyStyle(
    accent: Color(0xFF3FA66B),
    tagline: '5×5 board with plenty of help',
  ),
  Difficulty.medium: DifficultyStyle(
    accent: Color(0xFF3F7FB5),
    tagline: 'The classic 4×4 experience',
  ),
  Difficulty.hard: DifficultyStyle(
    accent: Color(0xFFD9822B),
    tagline: 'Clutter, extra tiles, mean spawns',
  ),
  Difficulty.veryHard: DifficultyStyle(
    accent: Color(0xFFB93A5B),
    tagline: 'Stones plus hostile spawns',
  ),
};

/// Rule badges derived from the config, so the card always tells the truth
/// about what the difficulty actually does (PLAN.md §3.2).
List<String> ruleBadges(DifficultyConfig cfg) {
  final n = cfg.boardSize;
  return [
    '$n×$n board',
    'Goal ${cfg.targetTile}',
    if (cfg.blockedLayouts.isNotEmpty)
      '${cfg.blockedLayouts.first.length} stones',
    if (cfg.adversaryStrength > 0) 'Mean spawns',
    if (cfg.doubleSpawnEvery > 0) 'Extra tile every ${cfg.doubleSpawnEvery}',
    if (cfg.undoLimit == 0) 'No undo' else 'Undo ×${cfg.undoLimit}',
  ];
}
