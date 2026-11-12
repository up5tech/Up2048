import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/direction.dart';
import '../widgets/board_view.dart';
import '../widgets/game_toolbar.dart';
import '../widgets/result_dialog.dart';
import '../widgets/score_panel.dart';
import '../widgets/swipe_detector.dart';

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;
  const GameScreen({super.key, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _dialogOpen = false;
  GameStatus _lastHandledStatus = GameStatus.playing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameController>().newGame(widget.difficulty);
    });
  }

  void _maybeShowDialog(GameController game) {
    // Only react to a status *transition*, so a dismissed dialog does not
    // reopen on every rebuild.
    if (game.status != GameStatus.won && game.status != GameStatus.over) {
      _lastHandledStatus = game.status;
      return;
    }
    if (_dialogOpen || game.status == _lastHandledStatus) return;
    _lastHandledStatus = game.status;
    if (game.status == GameStatus.won) {
      _dialogOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ResultDialog(
          game: game,
          kind: ResultKind.win,
          onKeepGoing: () {
            Navigator.of(context).pop();
            game.keepGoing();
          },
          onNewGame: () {
            Navigator.of(context).pop();
            _confirmNewGame(game);
          },
        ),
      ).then((_) => _dialogOpen = false);
    } else if (game.status == GameStatus.over) {
      _dialogOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ResultDialog(
          game: game,
          kind: ResultKind.gameOver,
          onKeepGoing: () {},
          onNewGame: () {
            Navigator.of(context).pop();
            _confirmNewGame(game);
          },
        ),
      ).then((_) => _dialogOpen = false);
    }
  }

  Future<void> _confirmNewGame(GameController game) async {
    if (!game.hasProgress) {
      game.newGame(widget.difficulty);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start a new game?'),
        content: const Text('Your current progress will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('New game')),
        ],
      ),
    );
    if (ok == true && mounted) game.newGame(widget.difficulty);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final game = context.read<GameController>();
    final map = <LogicalKeyboardKey, Direction>{
      LogicalKeyboardKey.arrowUp: Direction.up,
      LogicalKeyboardKey.arrowDown: Direction.down,
      LogicalKeyboardKey.arrowLeft: Direction.left,
      LogicalKeyboardKey.arrowRight: Direction.right,
      LogicalKeyboardKey.keyW: Direction.up,
      LogicalKeyboardKey.keyA: Direction.left,
      LogicalKeyboardKey.keyS: Direction.down,
      LogicalKeyboardKey.keyD: Direction.right,
    };
    final d = map[event.logicalKey];
    if (d == null) return KeyEventResult.ignored;
    game.swipe(d);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    // Trigger dialogs after the frame in which status changed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDialog(game));

    return Scaffold(
      appBar: AppBar(
        title: Text('${kDifficulties[widget.difficulty]!.label} — Up2048'),
        actions: [
          IconButton(
            tooltip: 'New game',
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmNewGame(game),
          ),
        ],
      ),
      body: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: _onKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScorePanel(game: game),
              ),
              Expanded(
                child: Center(
                  child: SwipeDetector(
                    onSwipe: game.swipe,
                    child: BoardView(board: game.board),
                  ),
                ),
              ),
              GameToolbar(
                game: game,
                onNewGame: () => _confirmNewGame(game),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
