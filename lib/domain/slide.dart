import 'models/board.dart';
import 'models/direction.dart';
import 'models/move_result.dart';

/// Cell indices of line [k], ordered from the edge tiles slide TOWARD,
/// moving outward. Sliding "left" on row k → [k*size + 0, k*size + 1, ...].
List<int> lineIndices(int size, Direction d, int k) {
  switch (d) {
    case Direction.left:
      return [for (var c = 0; c < size; c++) k * size + c];
    case Direction.right:
      return [for (var c = size - 1; c >= 0; c--) k * size + c];
    case Direction.up:
      return [for (var r = 0; r < size; r++) r * size + k];
    case Direction.down:
      return [for (var r = size - 1; r >= 0; r--) r * size + k];
  }
}

/// Slides and merges the whole board. Never mutates [b].
MoveResult slide(Board b, Direction d) {
  final out = List<int>.of(b.cells);
  final motions = <TileMotion>[];
  var gained = 0;

  for (var k = 0; k < b.size; k++) {
    final line = lineIndices(b.size, d, k);
    var segStart = 0;
    for (var i = 0; i <= line.length; i++) {
      final atEnd = i == line.length;
      if (atEnd || b.cells[line[i]] == kBlock) {
        if (i > segStart) {
          gained += _slideSegment(b, line.sublist(segStart, i), out, motions);
        }
        segStart = i + 1;
      }
    }
  }
  return MoveResult(Board(b.size, out), gained, motions);
}

/// Slides one block-free segment. Returns the score gained.
int _slideSegment(
    Board b, List<int> seg, List<int> out, List<TileMotion> motions) {
  // Indices of non-empty cells, in order from the leading edge.
  final tiles = [
    for (final idx in seg)
      if (b.cells[idx] != kEmpty) idx,
  ];
  for (final idx in seg) {
    out[idx] = kEmpty;
  }

  var write = 0;
  var gained = 0;
  var i = 0;
  while (i < tiles.length) {
    final from = tiles[i];
    final v = b.cells[from];
    final to = seg[write];

    if (i + 1 < tiles.length && b.cells[tiles[i + 1]] == v) {
      out[to] = v * 2;
      gained += v * 2;
      motions
        ..add(TileMotion(from, to, v, true))
        ..add(TileMotion(tiles[i + 1], to, v, true));
      i += 2;
    } else {
      out[to] = v;
      motions.add(TileMotion(from, to, v, false));
      i += 1;
    }
    write++;
  }
  return gained;
}

/// True if at least one direction changes the board.
bool canMove(Board b) {
  for (final d in Direction.values) {
    if (slide(b, d).moved) return true;
  }
  return false;
}
