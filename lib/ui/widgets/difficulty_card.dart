import 'package:flutter/material.dart';

import '../../core/difficulty_style.dart';
import '../../domain/models/difficulty.dart';

/// One difficulty card: name, tagline, rule badges, personal best and the
/// play/continue actions (PLAN.md §13.2).
class DifficultyCard extends StatelessWidget {
  final DifficultyConfig cfg;
  final int bestScore;
  final int bestTile;
  final bool hasSave;
  final VoidCallback onNewGame;
  final VoidCallback onContinue;

  const DifficultyCard({
    super.key,
    required this.cfg,
    required this.bestScore,
    required this.bestTile,
    required this.hasSave,
    required this.onNewGame,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final style = kDifficultyStyles[cfg.id]!;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: style.accent.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: style.accent.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 42,
                  decoration: BoxDecoration(
                    color: style.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cfg.label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: style.accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        style.tagline,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final badge in ruleBadges(cfg))
                  _Badge(text: badge, color: style.accent),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              bestScore > 0
                  ? 'Best $bestScore · Best tile $bestTile'
                  : 'Not played yet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (hasSave) ...[
                  FilledButton(
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: style.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Continue'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onNewGame,
                    child: const Text('New game'),
                  ),
                ] else
                  FilledButton(
                    onPressed: onNewGame,
                    style: FilledButton.styleFrom(
                      backgroundColor: style.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Play'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
