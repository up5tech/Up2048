import 'package:flutter/material.dart';

import '../../controllers/game_controller.dart';

enum ResultKind { win, gameOver }

class ResultDialog extends StatelessWidget {
  final GameController game;
  final ResultKind kind;
  final VoidCallback onNewGame;
  final VoidCallback onKeepGoing;

  const ResultDialog({
    super.key,
    required this.game,
    required this.kind,
    required this.onNewGame,
    required this.onKeepGoing,
  });

  @override
  Widget build(BuildContext context) {
    final isWin = kind == ResultKind.win;
    return AlertDialog(
      title: Text(isWin
          ? 'You made ${game.board.maxTile}!'
          : 'Game over'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Score: ${game.score}'),
          Text('Moves: ${game.moves}'),
          Text('Best tile: ${game.board.maxTile}'),
        ],
      ),
      actions: [
        if (isWin)
          TextButton(onPressed: onKeepGoing, child: const Text('Keep going')),
        FilledButton(
            onPressed: onNewGame, child: const Text('New game')),
      ],
    );
  }
}
