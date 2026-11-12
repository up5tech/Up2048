import 'package:flutter_test/flutter_test.dart';
import 'package:up_2048/controllers/game_controller.dart';
import 'package:up_2048/domain/models/board.dart';
import 'package:up_2048/domain/models/difficulty.dart';
import 'package:up_2048/domain/models/direction.dart';

/// Plays [d] and reports whether the board changed.
Future<bool> trySwipe(GameController g, Direction d) async {
  final before = List<int>.of(g.board.cells);
  await g.swipe(d);
  return g.board.cells.join() != before.join();
}

/// Finds and plays the first direction that changes the board.
Future<bool> playAnyMove(GameController g) async {
  for (final d in Direction.values) {
    if (await trySwipe(g, d)) return true;
  }
  return false;
}

void main() {
  late GameController game;

  setUp(() {
    game = GameController();
    game.newGame(Difficulty.medium, seed: 1);
  });

  test('newGame creates a board matching the difficulty', () {
    expect(game.cfg.boardSize, 4);
    expect(game.board.cells, hasLength(16));
    expect(game.board.cells.where((v) => v > 0), hasLength(2));
    expect(game.score, 0);
    expect(game.moves, 0);
    expect(game.status, GameStatus.playing);
  });

  test('valid swipe increments moves and keeps board consistent', () async {
    final emptiesBefore = game.board.emptyIndices.length;
    expect(await playAnyMove(game), isTrue);
    expect(game.moves, 1);
    // One spawn per move → empties shrink by exactly 1 (unless merged).
    expect(game.board.emptyIndices.length, emptiesBefore - 1);
  });

  test('swipe that changes nothing is not a move', () async {
    // Fill the board into a state where left does nothing is complex;
    // instead verify on a fresh board that repeatedly spamming the same
    // direction eventually produces a no-op OR a move — both are legal.
    // Deterministic check: a board with a single tile in the left column
    // cannot move left.
    final g = GameController()..newGame(Difficulty.medium, seed: 3);
    // Minimal board: single tile already against the left edge.
    g.board = Board(4, [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
    final before = List<int>.of(g.board.cells);
    await g.swipe(Direction.left);
    expect(g.board.cells, before);
    expect(g.moves, 0);
  });

  test('swipe on terminal status is ignored', () async {
    game.status = GameStatus.over;
    final before = game.board.cells;
    await game.swipe(Direction.left);
    expect(game.board.cells, before);
    expect(game.moves, 0);
  });

  test('undo restores board, score and moves', () async {
    expect(await playAnyMove(game), isTrue);
    final movesAfter = game.moves;
    final scoreAfter = game.score;
    final cellsAfter = List<int>.of(game.board.cells);

    expect(game.canUndo, isTrue);
    game.undo();
    expect(game.moves, movesAfter - 1);
    expect(game.score, lessThanOrEqualTo(scoreAfter));
    expect(game.undoLeft, 2); // medium allows 3
    expect(cellsAfter, isNot(game.board.cells)); // spawn was rolled back
  });

  test('undo respects the per-difficulty limit', () {
    final g2 = GameController()..newGame(Difficulty.veryHard, seed: 5);
    expect(g2.canUndo, isFalse);
    g2.undo();
    expect(g2.moves, 0);
  });

  test('keepGoing is a no-op while playing', () {
    game.keepGoing();
    expect(game.status, GameStatus.playing);
  });

  test('reaching target tile sets status won; keepGoing resumes', () async {
    final g = GameController()..newGame(Difficulty.easy, seed: 2);
    // Plant the target tile on an empty corner, then make any valid move:
    // _updateStatus runs after the move resolves.
    final target = g.cfg.targetTile;
    var planted = -1;
    for (var i = 0; i < g.board.cells.length; i++) {
      if (g.board.cells[i] == 0) {
        planted = i;
        break;
      }
    }
    g.board = g.board.withCell(planted, target);
    expect(await playAnyMove(g), isTrue);
    expect(g.status, GameStatus.won);

    g.keepGoing();
    expect(g.status, GameStatus.keepPlaying);
  });

  test('hard difficulty plays to 10 moves (double-spawn path)', () async {
    final g = GameController()..newGame(Difficulty.hard, seed: 9);
    var guard = 0;
    while (g.moves < 10 && guard++ < 100) {
      await playAnyMove(g);
    }
    expect(g.moves, greaterThanOrEqualTo(10));
  });

  test('each difficulty starts a board matching its config', () {
    for (final d in Difficulty.values) {
      final g = GameController()..newGame(d, seed: 4);
      final cfg = kDifficulties[d]!;
      expect(g.cfg.id, d);
      expect(g.board.size, cfg.boardSize, reason: d.name);
      expect(g.board.cells, hasLength(cfg.boardSize * cfg.boardSize));
      expect(g.board.cells.where((v) => v > 0).length, cfg.initialTiles,
          reason: '${d.name} initial tiles');
      expect(
        g.board.cells.where((v) => v == kBlock).length,
        cfg.blockedLayouts.isEmpty ? 0 : cfg.blockedLayouts.first.length,
        reason: '${d.name} stones',
      );
    }
  });

  // A single tile at the right end of row 0 slides left without merging,
  // so the tile count after a move is `1 + spawns`.
  Board oneSlidingTile() => Board(4, [
        0, 0, 0, 2, //
        0, 0, 0, 0, //
        0, 0, 0, 0, //
        0, 0, 0, 0, //
      ]);

  test('medium spawns exactly one tile per move', () async {
    final g = GameController()..newGame(Difficulty.medium, seed: 12);
    g.board = oneSlidingTile();
    await g.swipe(Direction.left);
    expect(g.moves, 1);
    expect(g.board.cells.where((v) => v > 0).length, 2);
  });

  test('tiles stay in sync with the board and settle after each move',
      () async {
    expect(await playAnyMove(game), isTrue);
    final occupied = {
      for (var i = 0; i < game.board.cells.length; i++)
        if (game.board.cells[i] > 0) i,
    };
    expect(game.tiles, hasLength(occupied.length));
    expect(game.tiles.map((t) => t.index).toSet(), occupied);
    expect(game.tiles.map((t) => t.id).toSet(), hasLength(occupied.length));
    expect(game.tiles.any((t) => t.isGhost || t.isNew || t.isMerged), isFalse);
  });

  test('a swipe during the animation is buffered and replayed once', () async {
    // Fire two swipes back to back: the second must not be dropped.
    final first = game.swipe(Direction.left);
    final second = game.swipe(Direction.right);
    await first;
    await second;
    expect(game.moves, greaterThanOrEqualTo(1));
    final occupied = game.board.cells.where((v) => v > 0).length;
    expect(game.tiles, hasLength(occupied));
  });

  for (final d in [Difficulty.hard, Difficulty.veryHard]) {
    test('${d.name} spawns two tiles on the configured move', () async {
      final g = GameController()..newGame(d, seed: 12);
      final every = g.cfg.doubleSpawnEvery;
      expect(every, greaterThan(0));
      g.moves = every - 1;
      g.board = oneSlidingTile();
      await g.swipe(Direction.left);
      expect(g.moves, every);
      expect(g.board.cells.where((v) => v > 0).length, 3);
    });
  }

  test('hint costs one use and returns a direction', () async {
    final g = GameController()..newGame(Difficulty.easy, seed: 2);
    final limit = kDifficulties[Difficulty.easy]!.hintLimit;
    expect(g.canHint, isTrue);

    await g.requestHint();

    expect(g.hint, isNotNull);
    expect(g.hintsLeft, limit - 1);
    expect(g.hintLoading, isFalse);
  });

  test('difficulties without hints never hint', () async {
    final g = GameController()..newGame(Difficulty.hard, seed: 2);
    expect(g.canHint, isFalse);

    await g.requestHint();

    expect(g.hint, isNull);
    expect(g.hintsLeft, 0);
  });

  test('remove tile clears a tile and costs one use', () {
    final g = GameController()..newGame(Difficulty.easy, seed: 2);
    final before = g.removeLeft;
    final index = g.board.cells.indexWhere((v) => v > 0);

    g.removeTile(index);

    expect(g.board.cells[index], 0);
    expect(g.removeLeft, before - 1);
  });

  test('remove tile ignores empty cells and stones', () {
    final g = GameController()..newGame(Difficulty.easy, seed: 2);
    final before = g.removeLeft;
    final empty = g.board.cells.indexWhere((v) => v == 0);

    g.removeTile(empty);
    g.board = g.board.withCell(0, kBlock);
    g.removeTile(0);

    expect(g.removeLeft, before);
    expect(g.board.cells[0], kBlock);
  });

  test('remove tile is disabled when the difficulty grants none', () {
    final g = GameController()..newGame(Difficulty.veryHard, seed: 2);
    expect(g.canRemove, isFalse);
    final index = g.board.cells.indexWhere((v) => v > 0);
    final value = g.board.cells[index];

    g.removeTile(index);

    expect(g.board.cells[index], value);
  });
}
