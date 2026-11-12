import 'dart:math';

import 'expectimax_bot.dart';
import 'models/board.dart';
import 'models/difficulty.dart';

/// Best move index for a plain description of a board, or -1 when no move
/// exists. Kept free of Flutter types so it can run inside an isolate.
int hintIndexForBoard(
  int size,
  List<int> cells,
  List<SpawnWeight> spawnTable, {
  int? seed,
}) {
  final bot = ExpectimaxBot(depth: 2, rng: Random(seed));
  final dir = bot.bestMove(Board(size, List<int>.of(cells)), spawnTable);
  return dir?.index ?? -1;
}
