import 'dart:math';

import 'evaluate.dart';
import 'models/board.dart';
import 'models/difficulty.dart';
import 'models/direction.dart';
import 'slide.dart';

/// Expectimax search: max over the player's moves, chance over spawns
/// (PLAN.md §11.2).
class ExpectimaxBot {
  /// Player moves to look ahead (1–3).
  final int depth;

  /// Cap on empty cells sampled per chance node.
  final int maxChanceSamples;

  final Random rng;

  ExpectimaxBot({
    this.depth = 2,
    this.maxChanceSamples = 6,
    Random? rng,
  }) : rng = rng ?? Random();

  /// Best direction for [b], or null if no move exists.
  Direction? bestMove(Board b, List<SpawnWeight> table) {
    Direction? best;
    var bestScore = double.negativeInfinity;
    for (final d in Direction.values) {
      final r = slide(b, d);
      if (!r.moved) continue;
      final s = _chance(r.board, table, depth - 1);
      if (s > bestScore) {
        bestScore = s;
        best = d;
      }
    }
    return best;
  }

  double _max(Board b, List<SpawnWeight> table, int depth) {
    if (depth <= 0) return evaluate(b);
    var best = double.negativeInfinity;
    for (final d in Direction.values) {
      final r = slide(b, d);
      if (!r.moved) continue;
      best = max(best, _chance(r.board, table, depth - 1));
    }
    // No move exists: a lost position.
    return best == double.negativeInfinity ? -1e9 : best;
  }

  double _chance(Board b, List<SpawnWeight> table, int depth) {
    final empties = b.emptyIndices;
    if (empties.isEmpty) return _max(b, table, depth);

    final sample = empties.length <= maxChanceSamples
        ? empties
        : (List<int>.of(empties)..shuffle(rng)).take(maxChanceSamples).toList();
    final totalWeight = table.fold<int>(0, (s, e) => s + e.weight);

    var expected = 0.0;
    for (final i in sample) {
      for (final w in table) {
        expected += (w.weight / totalWeight) * _max(b.withCell(i, w.value), table, depth);
      }
    }
    return expected / sample.length;
  }
}
