import 'package:flutter/material.dart';

import '../domain/models/difficulty.dart';
import '../l10n/app_localizations.dart';

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

String difficultyLabel(AppLocalizations l10n, Difficulty d) => switch (d) {
      Difficulty.easy => l10n.difficultyEasy,
      Difficulty.medium => l10n.difficultyMedium,
      Difficulty.hard => l10n.difficultyHard,
      Difficulty.veryHard => l10n.difficultyVeryHard,
    };

String difficultyTagline(AppLocalizations l10n, Difficulty d) => switch (d) {
      Difficulty.easy => l10n.taglineEasy,
      Difficulty.medium => l10n.taglineMedium,
      Difficulty.hard => l10n.taglineHard,
      Difficulty.veryHard => l10n.taglineVeryHard,
    };

/// Rule badges derived from the config, so the card always tells the truth
/// about what the difficulty actually does (PLAN.md §3.2).
List<String> ruleBadges(AppLocalizations l10n, DifficultyConfig cfg) {
  final n = cfg.boardSize;
  return [
    l10n.badgeBoard(n),
    l10n.badgeGoal(cfg.targetTile),
    if (cfg.blockedLayouts.isNotEmpty)
      l10n.badgeStones(cfg.blockedLayouts.first.length),
    if (cfg.adversaryStrength > 0) l10n.badgeMeanSpawns,
    if (cfg.doubleSpawnEvery > 0)
      l10n.badgeExtraTile(cfg.doubleSpawnEvery),
    if (cfg.undoLimit == 0)
      l10n.badgeNoUndo
    else
      l10n.badgeUndo(cfg.undoLimit),
  ];
}
