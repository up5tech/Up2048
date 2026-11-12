import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/models/board.dart';
import '../domain/models/difficulty.dart';
import '../domain/models/direction.dart';
import '../domain/slide.dart';
import '../domain/spawner.dart';

enum GameStatus { playing, won, keepPlaying, over }

class _Snapshot {
  final Board board;
  final int score;
  final int moves;
  _Snapshot(this.board, this.score, this.moves);
}

class GameController extends ChangeNotifier {
  late DifficultyConfig cfg;
  late Board board;
  late Spawner _spawner;
  late Random _rng;

  int score = 0;
  int moves = 0;
  int undoLeft = 0;
  int hintsLeft = 0;
  int removeLeft = 0;
  GameStatus status = GameStatus.playing;
  Direction? hint;

  bool _animating = false;
  Direction? _queued; // one buffered swipe during animation
  final List<_Snapshot> _undo = [];

  static const _animMs = 140;

  /// Whether a game is in progress (used for "new game" confirmation).
  bool get hasProgress => moves > 0 || status != GameStatus.playing;

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
    _undo.clear();
    _animating = false;
    _queued = null;
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

    // 1 tile normally, 2 on "double spawn" moves
    var next = r.board;
    final count =
        1 + ((cfg.doubleSpawnEvery > 0 && moves % cfg.doubleSpawnEvery == 0)
            ? 1
            : 0);
    for (var i = 0; i < count; i++) {
      final s = _spawner.spawn(next);
      if (s == null) break;
      next = s.board;
    }
    board = next;
    notifyListeners();

    // Phase 2 has no tile animation yet; keep the cadence so fast swipes
    // still buffer correctly once TileView lands in Phase 4.
    await Future.delayed(const Duration(milliseconds: _animMs));
    _animating = false;

    _updateStatus();
    notifyListeners();

    final q = _queued;
    _queued = null;
    if (q != null) await swipe(q);
  }

  void _updateStatus() {
    if (status == GameStatus.playing && board.maxTile >= cfg.targetTile) {
      status = GameStatus.won;
    }
    if (status != GameStatus.won && !canMove(board)) {
      status = GameStatus.over;
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
    notifyListeners();
  }

  void removeTile(int cellIndex) {
    if (removeLeft <= 0 || _animating) return;
    if (board.cells[cellIndex] <= 0) return;
    _undo.add(_Snapshot(board, score, moves));
    if (_undo.length > 20) _undo.removeAt(0);
    board = board.withCell(cellIndex, kEmpty);
    removeLeft--;
    notifyListeners();
  }

  void keepGoing() {
    if (status == GameStatus.won) {
      status = GameStatus.keepPlaying;
      notifyListeners();
    }
  }
}
