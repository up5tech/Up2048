import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/audio_service.dart';
import '../data/storage_service.dart';
import '../domain/hint.dart';
import '../domain/models/board.dart';
import '../domain/models/difficulty.dart';
import '../domain/models/direction.dart';
import '../domain/models/save_data.dart';
import '../domain/models/tile_view.dart';
import '../domain/slide.dart';
import '../domain/spawner.dart';
import 'settings_controller.dart';
import 'stats_controller.dart';

enum GameStatus { playing, won, keepPlaying, over }

class _Snapshot {
  final Board board;
  final int score;
  final int moves;
  _Snapshot(this.board, this.score, this.moves);
}

/// Arguments for the hint isolate.
class _HintArgs {
  final int size;
  final List<int> cells;
  final List<SpawnWeight> spawnTable;
  final int seed;

  const _HintArgs(this.size, this.cells, this.spawnTable, this.seed);
}

int _hintInIsolate(_HintArgs args) => hintIndexForBoard(
      args.size,
      args.cells,
      args.spawnTable,
      seed: args.seed,
    );

class GameController extends ChangeNotifier {
  /// Optional collaborators: omitted in pure logic tests.
  final StorageService? storage;
  final StatsController? stats;
  final SettingsController? settings;
  final AudioService? audio;

  GameController({this.storage, this.stats, this.settings, this.audio});

  DifficultyConfig cfg = kDifficulties[Difficulty.medium]!;
  Board board = Board(4, List<int>.filled(16, kEmpty));
  Spawner? _spawner;
  Random _rng = Random();

  int score = 0;
  int moves = 0;
  int undoLeft = 0;
  int hintsLeft = 0;
  int removeLeft = 0;
  GameStatus status = GameStatus.playing;
  Direction? hint;

  /// True while the expectimax hint is being computed off the UI thread.
  bool hintLoading = false;

  /// Tiles the UI draws: stable ids plus one-shot animation flags.
  List<TileView> tiles = [];

  bool _systemReduceMotion = false;
  bool _winRecorded = false;
  bool _finishedRecorded = false;

  bool _animating = false;
  Direction? _queued; // one buffered swipe during animation
  final List<_Snapshot> _undo = [];
  bool _disposed = false;

  static const _animMs = 140;

  /// Reduce-motion from the settings screen or the platform setting.
  bool get reduceMotion =>
      _systemReduceMotion || (settings?.settings.reduceMotion ?? false);

  /// Platform reduce-motion setting, pushed in by the game screen.
  set systemReduceMotion(bool value) => _systemReduceMotion = value;

  /// Whether a game is in progress (used for "new game" confirmation).
  bool get hasProgress => moves > 0 || status != GameStatus.playing;

  bool get isAnimating => _animating;

  /// True when [d] has a saved game to resume.
  bool hasSavedGame(Difficulty d) => storage?.loadGame(d) != null;

  bool get _playable =>
      status == GameStatus.playing || status == GameStatus.keepPlaying;

  bool get canHint => hintsLeft > 0 && !hintLoading && !_animating && _playable;

  bool get canRemove => removeLeft > 0 && !_animating && _playable;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void newGame(Difficulty d, {int? seed}) {
    cfg = kDifficulties[d]!;
    _rng = Random(seed);
    _spawner = Spawner(cfg, _rng);
    board = createInitialBoard(cfg, _rng);
    score = 0;
    moves = 0;
    undoLeft = cfg.undoLimit;
    hintsLeft = cfg.hintLimit;
    removeLeft = cfg.removeTileLimit;
    status = GameStatus.playing;
    hint = null;
    hintLoading = false;
    _undo.clear();
    _animating = false;
    _queued = null;
    _winRecorded = false;
    _finishedRecorded = false;
    tiles = TileView.fromBoard(board);
    stats?.onGameStarted(d);
    _save();
    notifyListeners();
  }

  /// Restores the saved game for [d], or starts a new one when there is no
  /// usable save (missing, corrupted or from another board size).
  void resume(Difficulty d) {
    final saved = storage?.loadGame(d);
    final config = kDifficulties[d]!;
    if (saved == null ||
        saved.size != config.boardSize ||
        saved.cells.length != saved.size * saved.size) {
      newGame(d);
      return;
    }

    cfg = config;
    _rng = Random();
    _spawner = Spawner(cfg, _rng);
    board = Board(saved.size, List<int>.of(saved.cells));
    score = saved.score;
    moves = saved.moves;
    undoLeft = saved.undoLeft;
    hintsLeft = saved.hintsLeft;
    removeLeft = saved.removeLeft;
    status = (saved.keepPlaying || board.maxTile >= cfg.targetTile)
        ? GameStatus.keepPlaying
        : GameStatus.playing;
    if (!canMove(board)) status = GameStatus.over;
    hint = null;
    hintLoading = false;
    _undo.clear(); // undo history is not persisted (PLAN.md §16.2)
    _animating = false;
    _queued = null;
    _winRecorded = status != GameStatus.playing;
    _finishedRecorded = status == GameStatus.over;
    tiles = TileView.fromBoard(board);
    notifyListeners();
  }

  Future<void> swipe(Direction d) async {
    if (status == GameStatus.over || status == GameStatus.won) return;
    if (_animating) {
      _queued = d;
      return;
    }

    final r = slide(board, d);
    if (!r.moved) return; // not a move: no spawn, no counter, no sound

    hint = null;
    _undo.add(_Snapshot(board, score, moves));
    if (_undo.length > 20) _undo.removeAt(0);

    _animating = true;
    score += r.gained;
    moves++;

    var biggestMerge = 0;
    for (final m in r.motions) {
      if (m.merged && m.value * 2 > biggestMerge) biggestMerge = m.value * 2;
    }

    // 1 tile normally, 2 on "double spawn" moves
    var next = r.board;
    final spawnedAt = <int>[];
    final count =
        1 + ((cfg.doubleSpawnEvery > 0 && moves % cfg.doubleSpawnEvery == 0)
            ? 1
            : 0);
    for (var i = 0; i < count; i++) {
      final s = _spawner?.spawn(next);
      if (s == null) break;
      next = s.board;
      spawnedAt.add(s.index);
    }
    board = next;

    // Hand the UI stable identities so tiles slide instead of teleporting.
    tiles = TileView.applyMove(tiles, r.motions, board, spawnedAt);
    _playSfx(r.gained > 0 ? Sfx.merge : Sfx.slide);
    _vibrate(biggestMerge >= 128 ? HapticFeedback.lightImpact : null);
    notifyListeners();

    await Future.delayed(Duration(milliseconds: reduceMotion ? 0 : _animMs));
    tiles = TileView.settle(tiles); // drop ghosts, clear animation flags
    _animating = false;

    _updateStatus();
    stats?.recordBest(cfg.id, score: score, bestTile: board.maxTile);
    _save();
    notifyListeners();

    final q = _queued;
    _queued = null;
    if (q != null) await swipe(q);
  }

  void _updateStatus() {
    if (status == GameStatus.playing && board.maxTile >= cfg.targetTile) {
      status = GameStatus.won;
      _playSfx(Sfx.win);
      _vibrate(HapticFeedback.mediumImpact);
      if (!_winRecorded) {
        _winRecorded = true;
        stats?.onWin(cfg.id);
      }
    }
    if (status != GameStatus.won && !canMove(board)) {
      if (status != GameStatus.over) _playSfx(Sfx.gameOver);
      _vibrate(HapticFeedback.heavyImpact);
      status = GameStatus.over;
    }
    if (!_finishedRecorded &&
        (status == GameStatus.over || status == GameStatus.won)) {
      _finishedRecorded = true;
      stats?.onGameFinished(
        cfg.id,
        score: score,
        bestTile: board.maxTile,
        moves: moves,
      );
    }
  }

  bool get canUndo =>
      _undo.isNotEmpty && !_animating && (cfg.undoLimit < 0 || undoLeft > 0);

  void undo() {
    if (!canUndo) return;
    final s = _undo.removeLast();
    board = s.board;
    score = s.score;
    moves = s.moves;
    if (cfg.undoLimit >= 0) undoLeft--;
    status = moves > 0 && board.maxTile >= cfg.targetTile
        ? GameStatus.keepPlaying
        : GameStatus.playing;
    if (!canMove(board)) status = GameStatus.over;
    hint = null;
    // Tile identities cannot be reconstructed for a restored board.
    tiles = TileView.fromBoard(board);
    _save();
    notifyListeners();
  }

  /// Asks the expectimax bot for a move. Costs one hint, only on success.
  Future<void> requestHint() async {
    if (!canHint) return;
    final args = _HintArgs(
      board.size,
      List<int>.of(board.cells),
      cfg.spawnTable,
      DateTime.now().microsecondsSinceEpoch,
    );
    final movesBefore = moves;
    hintLoading = true;
    notifyListeners();

    var index = -1;
    try {
      // Depth 2 expectimax is far too slow for the UI thread.
      index = await compute(_hintInIsolate, args);
    } catch (e) {
      debugPrint('Hint computation failed: $e');
    }

    hintLoading = false;
    if (_disposed) return;
    // The board changed while we were thinking: the answer is stale.
    if (index < 0 || moves != movesBefore) {
      notifyListeners();
      return;
    }
    hintsLeft--;
    hint = Direction.values[index];
    notifyListeners();
  }

  /// "Remove tile" power-up: deletes the tile at [cellIndex].
  void removeTile(int cellIndex) {
    if (!canRemove) return;
    if (cellIndex < 0 || cellIndex >= board.cells.length) return;
    if (board.cells[cellIndex] <= 0) return; // empty or a stone
    _undo.add(_Snapshot(board, score, moves));
    if (_undo.length > 20) _undo.removeAt(0);
    board = board.withCell(cellIndex, kEmpty);
    removeLeft--;
    hint = null;
    tiles = TileView.fromBoard(board);
    _save();
    notifyListeners();
  }

  void keepGoing() {
    if (status == GameStatus.won) {
      status = GameStatus.keepPlaying;
      _save();
      notifyListeners();
    }
  }

  /// Autosave hook (app paused, leaving the screen).
  Future<void> saveNow() => _save();

  void _playSfx(Sfx sfx) {
    if (settings?.settings.sound ?? false) audio?.play(sfx);
  }

  void _vibrate(Future<void> Function()? feedback) {
    if (feedback == null) return;
    if (!(settings?.settings.vibration ?? false)) return;
    feedback();
  }

  /// One save slot per difficulty; a finished game has no save.
  Future<void> _save() async {
    final store = storage;
    if (store == null) return;
    if (status == GameStatus.over || status == GameStatus.won) {
      await store.clearGame(cfg.id);
      return;
    }
    await store.saveGame(
      SavedGame(
        difficulty: cfg.id,
        size: board.size,
        cells: List<int>.of(board.cells),
        score: score,
        moves: moves,
        undoLeft: undoLeft,
        hintsLeft: hintsLeft,
        removeLeft: removeLeft,
        keepPlaying: status == GameStatus.keepPlaying,
      ),
    );
  }
}
