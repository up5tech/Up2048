import 'package:flutter/material.dart';

import '../../core/difficulty_style.dart';
import '../../domain/models/difficulty.dart';

/// One difficulty card: name, tagline and rule badges.
class DifficultyCard extends StatelessWidget {
  final DifficultyConfig cfg;
  final VoidCallback onTap;

  const DifficultyCard({super.key, required this.cfg, required this.onTap});

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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 46,
                decoration: BoxDecoration(
                  color: style.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final badge in ruleBadges(cfg))
                          _Badge(text: badge, color: style.accent),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: style.accent),
            ],
          ),
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
