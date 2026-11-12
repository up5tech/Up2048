import 'dart:math';

import 'evaluate.dart';
import 'models/board.dart';
import 'models/difficulty.dart';

int sampleValue(List<SpawnWeight> table, Random rng) {
  final total = table.fold<int>(0, (s, e) => s + e.weight);
  var roll = rng.nextInt(total);
  for (final e in table) {
    if (roll < e.weight) return e.value;
    roll -= e.weight;
  }
  return table.last.value;
}

class SpawnResult {
  final Board board;
  final int index;
  final int value;
  const SpawnResult(this.board, this.index, this.value);
}

class Spawner {
  final DifficultyConfig cfg;
  final Random rng;
  Spawner(this.cfg, this.rng);

  /// Spawns one tile, or returns null if no cell is free.
  SpawnResult? spawn(Board b) {
    final empties = b.emptyIndices;
    if (empties.isEmpty) return null;

    final value = sampleValue(cfg.spawnTable, rng);
    final useAdversary =
        cfg.adversaryStrength > 0 && rng.nextDouble() < cfg.adversaryStrength;

    final index = useAdversary
        ? _worstCell(b, empties, value)
        : empties[rng.nextInt(empties.length)];

    return SpawnResult(b.withCell(index, value), index, value);
  }

  /// The empty cell that leaves the player in the worst position
  /// according to [evaluate] (lowest score = worst for the player).
  int _worstCell(Board b, List<int> empties, int value) {
    var worst = empties.first;
    var worstScore = double.infinity;
    for (final i in empties) {
      final s = evaluate(b.withCell(i, value));
      if (s < worstScore || (s == worstScore && rng.nextBool())) {
        worstScore = s;
        worst = i;
      }
    }
    return worst;
  }
}

/// Builds the starting board for a difficulty: blocks first, then tiles.
Board createInitialBoard(DifficultyConfig cfg, Random rng) {
  final cells = List<int>.filled(cfg.boardSize * cfg.boardSize, kEmpty);
  if (cfg.blockedLayouts.isNotEmpty) {
    final layout = cfg.blockedLayouts[rng.nextInt(cfg.blockedLayouts.length)];
    for (final i in layout) {
      cells[i] = kBlock;
    }
  }
  var board = Board(cfg.boardSize, cells);
  final spawner = Spawner(cfg, rng);
  for (var i = 0; i < cfg.initialTiles; i++) {
    board = spawner.spawn(board)!.board;
  }
  return board;
}
