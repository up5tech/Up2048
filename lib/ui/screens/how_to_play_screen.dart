import 'package:flutter/material.dart';

import '../../core/difficulty_style.dart';
import '../../domain/models/difficulty.dart';

/// Short rules recap and a summary of each difficulty (PLAN.md §13.2).
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _steps = [
    ('Swipe or use arrow keys', 'All tiles slide in that direction.'),
    ('Equal tiles merge', 'Two 2s become a 4, and the merged value is scored.'),
    ('Each tile merges once', '[2, 2, 2, 2] sliding left gives [4, 4], not 8.'),
    ('Reach the goal tile', 'The target value wins the game — you can keep playing.'),
    ('No moves left, game over', 'Stones split lines, so plan around them.'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('How to play')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          for (var i = 0; i < _steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _steps[i].$1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _steps[i].$2,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 32),
          Text(
            'Difficulties',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final d in Difficulty.values) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: kDifficultyStyles[d]!.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        kDifficulties[d]!.label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kDifficultyStyles[d]!.tagline,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ruleBadges(kDifficulties[d]!).join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
