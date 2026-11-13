import 'package:flutter/material.dart';

import '../../controllers/game_controller.dart';
import '../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    final isWin = kind == ResultKind.win;
    return AlertDialog(
      title: Text(isWin
          ? l10n.resultWinTitle(game.board.maxTile)
          : l10n.gameOverTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.scoreLine(game.score)),
          Text(l10n.movesLine(game.moves)),
          Text(l10n.bestTileLine(game.board.maxTile)),
        ],
      ),
      actions: [
        if (isWin)
          TextButton(onPressed: onKeepGoing, child: Text(l10n.keepGoing)),
        FilledButton(
            onPressed: onNewGame, child: Text(l10n.newGameButton)),
      ],
    );
  }
}
