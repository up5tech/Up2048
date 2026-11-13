import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/stats_controller.dart';
import '../../core/difficulty_style.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/save_data.dart';

/// Per-difficulty statistics plus career points (PLAN.md §13.2, §18).
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsController>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_outlined),
                  const SizedBox(width: 12),
                  Text(l10n.careerPoints,
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    '${stats.careerPoints}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final d in Difficulty.values) ...[
            _DifficultyStatsCard(
              difficulty: d,
              stats: stats.statsFor(d),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DifficultyStatsCard extends StatelessWidget {
  final Difficulty difficulty;
  final DifficultyStats stats;

  const _DifficultyStatsCard({
    required this.difficulty,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final style = kDifficultyStyles[difficulty]!;
    final l10n = AppLocalizations.of(context);
    final winRate = stats.gamesPlayed == 0
        ? '—'
        : '${(100 * stats.wins / stats.gamesPlayed).round()}%';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: style.accent.withValues(alpha: 0.14),
            child: Text(
              difficultyLabel(l10n, difficulty),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: style.accent,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                _Row(label: l10n.gamesPlayed, value: '${stats.gamesPlayed}'),
                _Row(label: l10n.wins, value: '${stats.wins}'),
                _Row(label: l10n.winRate, value: winRate),
                _Row(label: l10n.bestScore, value: '${stats.bestScore}'),
                _Row(label: l10n.bestTile, value: '${stats.bestTile}'),
                _Row(label: l10n.totalMoves, value: '${stats.totalMoves}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
