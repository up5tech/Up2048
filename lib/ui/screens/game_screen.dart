import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/difficulty_style.dart';
import '../../domain/models/difficulty.dart';
import '../../domain/models/direction.dart';
import '../widgets/board_view.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/game_toolbar.dart';
import '../widgets/result_dialog.dart';
import '../widgets/score_panel.dart';
import '../widgets/swipe_detector.dart';

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;

  /// Resume the saved game for [difficulty] instead of starting a new one.
  final bool resume;

  const GameScreen({
    super.key,
    required this.difficulty,
    this.resume = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  bool _dialogOpen = false;
  bool _removing = false;
  GameStatus _lastHandledStatus = GameStatus.playing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final game = context.read<GameController>();
      if (widget.resume) {
        game.resume(widget.difficulty);
      } else {
        game.newGame(widget.difficulty);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Follow the platform "reduce motion" accessibility setting.
    context.read<GameController>().systemReduceMotion =
        MediaQuery.of(context).disableAnimations;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Autosave when the app goes to the background (PLAN.md §16.2).
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (mounted) context.read<GameController>().saveNow();
    }
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
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newGameConfirmTitle),
        content: Text(l10n.newGameConfirmContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.newGameButton)),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _removing = false);
      game.newGame(widget.difficulty);
    }
  }

  void _toggleRemove(GameController game) {
    if (_removing) {
      setState(() => _removing = false);
      return;
    }
    if (!game.canRemove) return;
    setState(() => _removing = true);
  }

  void _onCellTap(GameController game, int index) {
    if (!_removing) return;
    final before = game.removeLeft;
    game.removeTile(index);
    // Leaving the mode only when the tile was actually removed; tapping an
    // empty cell or a stone keeps the power-up active (PLAN.md §19 #14).
    if (game.removeLeft != before) setState(() => _removing = false);
  }

  void _onSwipe(GameController game, Direction d) {
    if (_removing) return; // swipes are ignored while deleting a tile
    game.swipe(d);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_removing) return KeyEventResult.ignored;
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
    // Rebuild when motion preferences change so animations follow them.
    context.watch<SettingsController>();
    // Trigger dialogs after the frame in which status changed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDialog(game));

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: kDifficultyStyles[widget.difficulty]!.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text('${difficultyLabel(l10n, widget.difficulty)} — ${l10n.appTitle}'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.tooltipNewGame,
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
                    onSwipe: (d) => _onSwipe(game, d),
                    child: BoardView(
                      board: game.board,
                      tiles: game.tiles,
                      reduceMotion: game.reduceMotion,
                      hint: game.hint,
                      onCellTap: _removing
                          ? (index) => _onCellTap(game, index)
                          : null,
                    ),
                  ),
                ),
              ),
              GameToolbar(
                game: game,
                removeActive: _removing,
                onNewGame: () => _confirmNewGame(game),
                onHint: () => game.requestHint(),
                onToggleRemove: () => _toggleRemove(game),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
