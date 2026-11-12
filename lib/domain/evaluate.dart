import 'dart:math';

import 'models/board.dart';

/// Tiles are always powers of two, so log2 is exactly the bit length − 1.
/// This is both faster and exact compared with log(v)/ln2.
double _log2(int v) => (v.bitLength - 1).toDouble();

/// Higher score = better for the player (PLAN.md §11.1).
///
/// Used by the bot for hints/simulations and by the adversary to choose the
/// cell that hurts most, so one heuristic defines "good" everywhere.
///
/// Weights were tuned with `tool/simulate.dart` (see BALANCING.md).
double evaluate(Board b) {
  final n = b.size;
  final cells = b.cells;
  var empty = 0;
  var mergeable = 0.0; // log-weighted: merging big tiles matters more
  var smoothness = 0.0;
  var maxTile = 0;

  for (var r = 0; r < n; r++) {
    final rowStart = r * n;
    for (var c = 0; c < n; c++) {
      final i = rowStart + c;
      final v = cells[i];
      if (v == kEmpty) {
        empty++;
        continue;
      }
      if (v == kBlock) continue;
      if (v > maxTile) maxTile = v;

      if (c + 1 < n) {
        final w = cells[i + 1];
        if (w > 0) {
          final lv = _log2(v);
          final lw = _log2(w);
          smoothness -= (lv - lw).abs();
          if (v == w) mergeable += lv;
        }
      }
      if (r + 1 < n) {
        final w = cells[i + n];
        if (w > 0) {
          final lv = _log2(v);
          final lw = _log2(w);
          smoothness -= (lv - lw).abs();
          if (v == w) mergeable += lv;
        }
      }
    }
  }

  final corners = [0, n - 1, n * (n - 1), n * n - 1];
  final maxInCorner =
      maxTile > 0 && corners.any((i) => cells[i] == maxTile);

  return 500.0 * empty +
      60.0 * mergeable +
      12.0 * smoothness +
      150.0 * _monotonicity(b) +
      20.0 * (maxTile > 0 ? _log2(maxTile) : 0.0) +
      (maxInCorner ? 200.0 * _log2(maxTile) : 0.0);
}

/// Sum of the best (non-decreasing or non-increasing) direction per row and
/// column: rewards keeping tiles ordered, which is what makes large merges
/// possible. Stones and empty cells break a run.
double _monotonicity(Board b) {
  final n = b.size;
  final cells = b.cells;
  var total = 0.0;

  double lineMono(int start, int step) {
    var inc = 0.0;
    var dec = 0.0;
    for (var i = 1; i < n; i++) {
      final prev = cells[start + (i - 1) * step];
      final cur = cells[start + i * step];
      if (prev == kBlock || cur == kBlock || prev == kEmpty || cur == kEmpty) {
        continue;
      }
      final lp = _log2(prev);
      final lc = _log2(cur);
      if (lp > lc) {
        inc += lc - lp;
      } else {
        dec += lp - lc;
      }
    }
    return max(inc, dec);
  }

  for (var r = 0; r < n; r++) {
    total += lineMono(r * n, 1);
  }
  for (var c = 0; c < n; c++) {
    total += lineMono(c, n);
  }
  return total;
}
