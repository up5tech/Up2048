import 'board.dart';

/// One tile travelling from cell [from] to cell [to] during a move.
class TileMotion {
  final int from;
  final int to;
  final int value; // value BEFORE merging
  final bool merged; // true if this tile merges into another tile at [to]
  const TileMotion(this.from, this.to, this.value, this.merged);
}

class MoveResult {
  final Board board;
  final int gained; // score gained by merges
  final List<TileMotion> motions;
  const MoveResult(this.board, this.gained, this.motions);

  /// A move counts only if at least one tile moved or merged.
  bool get moved => motions.any((m) => m.from != m.to || m.merged);
}
