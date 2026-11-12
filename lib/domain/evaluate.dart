import 'dart:math';

import 'models/board.dart';

double _log2(int v) => log(v) / ln2;

double evaluate(Board b) {
  final n = b.size;
  var empty = 0;
  var mergeable = 0;
  var smoothness = 0.0;
  var maxTile = 0;

  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      final v = b.cells[r * n + c];
      if (v == kEmpty) {
        empty++;
        continue;
      }
      if (v == kBlock) continue;
      if (v > maxTile) maxTile = v;

      if (c + 1 < n) {
        final w = b.cells[r * n + c + 1];
        if (w > 0) {
          smoothness -= (_log2(v) - _log2(w)).abs();
          if (v == w) mergeable++;
        }
      }
      if (r + 1 < n) {
        final w = b.cells[(r + 1) * n + c];
        if (w > 0) {
          smoothness -= (_log2(v) - _log2(w)).abs();
          if (v == w) mergeable++;
        }
      }
    }
  }

  final corners = [0, n - 1, n * (n - 1), n * n - 1];
  final maxInCorner =
      maxTile > 0 && corners.any((i) => b.cells[i] == maxTile);

  return 270.0 * empty +
      100.0 * mergeable +
      10.0 * smoothness +
      (maxInCorner ? 200.0 * _log2(maxTile) : 0.0);
}
