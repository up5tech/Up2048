import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:up_2048/domain/evaluate.dart';
import 'package:up_2048/domain/expectimax_bot.dart';
import 'package:up_2048/domain/hint.dart';
import 'package:up_2048/domain/models/board.dart';
import 'package:up_2048/domain/models/difficulty.dart';
import 'package:up_2048/domain/models/direction.dart';

const table = [SpawnWeight(2, 90), SpawnWeight(4, 10)];

void main() {
  test('bot returns null when no move exists', () {
    // Checkerboard of distinct neighbours: nothing can move or merge.
    final stuck = Board(4, [
      2, 4, 2, 4, //
      4, 2, 4, 2, //
      2, 4, 2, 4, //
      4, 2, 4, 2, //
    ]);
    final bot = ExpectimaxBot(depth: 2, rng: Random(1));

    expect(bot.bestMove(stuck, table), isNull);
    expect(hintIndexForBoard(4, stuck.cells, table, seed: 1), -1);
  });

  test('bot prefers the move that merges', () {
    // 2 2 2 2 in the bottom row: only horizontal moves merge anything.
    final cells = List<int>.filled(16, 0);
    cells[12] = 2;
    cells[13] = 2;
    cells[14] = 2;
    cells[15] = 2;

    final bot = ExpectimaxBot(depth: 2, rng: Random(7));
    final best = bot.bestMove(Board(4, cells), table);
    expect(
      best == Direction.left || best == Direction.right,
      isTrue,
      reason: 'vertical moves merge nothing, got $best',
    );

    final hint = hintIndexForBoard(4, cells, table, seed: 7);
    expect(hint, anyOf(Direction.left.index, Direction.right.index));
  });

  test('evaluate ranks an open board above a cluttered one', () {
    final open = Board(4, [
      2, 0, 0, 0, //
      0, 0, 0, 0, //
      0, 0, 0, 0, //
      0, 0, 0, 0, //
    ]);
    final cluttered = Board(4, [
      2, 4, 8, 16, //
      32, 64, 128, 256, //
      512, 1024, 2048, 4096, //
      2, 4, 8, 16, //
    ]);

    expect(evaluate(open), greaterThan(evaluate(cluttered)));
  });
}
