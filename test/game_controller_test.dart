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
}
