import 'package:flutter/material.dart';

import '../../controllers/game_controller.dart';
import '../../l10n/app_localizations.dart';

class GameToolbar extends StatelessWidget {
  final GameController game;
  final bool removeActive;
  final VoidCallback onNewGame;
  final VoidCallback onHint;
  final VoidCallback onToggleRemove;

  const GameToolbar({
    super.key,
    required this.game,
    required this.removeActive,
    required this.onNewGame,
    required this.onHint,
    required this.onToggleRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonalIcon(
            onPressed: game.canUndo ? game.undo : null,
            icon: const Icon(Icons.undo, size: 18),
            label: Text(l10n.undoLabel(
                game.undoLeft < 0 ? '∞' : '${game.undoLeft}')),
          ),
          // Tool buttons only exist on difficulties that grant them.
          if (game.cfg.hintLimit > 0)
            FilledButton.tonalIcon(
              onPressed: game.canHint ? onHint : null,
              icon: Icon(
                game.hintLoading
                    ? Icons.hourglass_empty
                    : Icons.lightbulb_outline,
                size: 18,
              ),
              label: Text(l10n.hintLabel(game.hintsLeft)),
            ),
          if (game.cfg.removeTileLimit > 0)
            FilledButton.tonalIcon(
              onPressed: game.canRemove ? onToggleRemove : null,
              icon: Icon(
                removeActive ? Icons.cancel_outlined : Icons.layers_clear,
                size: 18,
              ),
              label: Text(
                removeActive
                    ? l10n.cancelLabel
                    : l10n.removeLabel(game.removeLeft),
              ),
            ),
          FilledButton.tonalIcon(
            onPressed: onNewGame,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.newGameButton),
          ),
        ],
      ),
    );
  }
}
