import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/stats_controller.dart';
import '../../core/difficulty_style.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/save_data.dart';

/// Per-difficulty statistics plus career points (PLAN.md §13.2, §18).
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
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
                  const Text('Career points',
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
              kDifficulties[difficulty]!.label,
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
                _Row(label: 'Games played', value: '${stats.gamesPlayed}'),
                _Row(label: 'Wins', value: '${stats.wins}'),
                _Row(label: 'Win rate', value: winRate),
                _Row(label: 'Best score', value: '${stats.bestScore}'),
                _Row(label: 'Best tile', value: '${stats.bestTile}'),
                _Row(label: 'Total moves', value: '${stats.totalMoves}'),
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
