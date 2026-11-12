import 'package:flutter/material.dart';

import '../../controllers/game_controller.dart';

class GameToolbar extends StatelessWidget {
  final GameController game;
  final VoidCallback onNewGame;
  const GameToolbar({
    super.key,
    required this.game,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton.tonalIcon(
            onPressed: game.canUndo ? game.undo : null,
            icon: const Icon(Icons.undo, size: 18),
            label: Text('Undo (${game.undoLeft < 0 ? '∞' : game.undoLeft})'),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: onNewGame,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('New game'),
          ),
        ],
      ),
    );
  }
}
