import 'package:flutter/material.dart';

import '../../controllers/game_controller.dart';

class ScorePanel extends StatelessWidget {
  final GameController game;
  const ScorePanel({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Stat(label: 'SCORE', value: '${game.score}', scheme: scheme),
        _Stat(label: 'MOVES', value: '${game.moves}', scheme: scheme),
        _Stat(label: 'BEST', value: '${game.board.maxTile}', scheme: scheme),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme scheme;
  const _Stat({required this.label, required this.value, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant)),
          Text(value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
