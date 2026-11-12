import 'board.dart';
import 'move_result.dart';

/// A tile with a stable identity for the render layer (PLAN.md §15.1).
///
/// The board only knows integers; the UI needs identity so a tile can animate
/// from one cell to another instead of being recreated at its new position.
class TileView {
  final int id;
  final int value;
  final int index; // current cell, row-major
  final bool isNew; // just spawned → "pop in"
  final bool isMerged; // result of a merge → "bump"
  final bool isGhost; // slides to its destination, then disappears

  const TileView(
    this.id,
    this.value,
    this.index, {
    this.isNew = false,
    this.isMerged = false,
    this.isGhost = false,
  });

  static int _nextId = 0;

  static int newId() => _nextId++;

  /// One tile per occupied cell, with fresh identities.
  static List<TileView> fromBoard(Board b) => [
        for (var i = 0; i < b.cells.length; i++)
          if (b.cells[i] > 0) TileView(newId(), b.cells[i], i),
      ];

  /// Applies [motions] to [tiles] and adds the freshly spawned tiles.
  ///
  /// - one motion to a cell: the tile keeps its id and moves;
  /// - two motions to a cell: both sources become ghosts sliding there, and a
  ///   new merged tile (new id) appears on top;
  /// - every cell in [spawnedAt] gets a new tile flagged [TileView.isNew].
  static List<TileView> applyMove(
    List<TileView> tiles,
    List<TileMotion> motions,
    Board board,
    List<int> spawnedAt,
  ) {
    final byCell = <int, TileView>{
      for (final t in tiles)
        if (!t.isGhost) t.index: t,
    };

    // Group motions by destination: 1 = slide, 2 = merge.
    final byDest = <int, List<TileMotion>>{};
    for (final m in motions) {
      (byDest[m.to] ??= <TileMotion>[]).add(m);
    }

    final out = <TileView>[];
    for (final entry in byDest.entries) {
      final to = entry.key;
      final group = entry.value;
      if (group.length > 1) {
        for (final m in group) {
          final from = byCell[m.from];
          out.add(TileView(from?.id ?? newId(), m.value, to, isGhost: true));
        }
        out.add(TileView(newId(), board.cells[to], to, isMerged: true));
      } else {
        final m = group.first;
        final from = byCell[m.from];
        out.add(TileView(from?.id ?? newId(), board.cells[to], to));
      }
    }

    for (final i in spawnedAt) {
      if (board.cells[i] <= 0) continue;
      out.add(TileView(newId(), board.cells[i], i, isNew: true));
    }

    // Safety net: if [tiles] was stale (e.g. a board restored from a save),
    // never let an occupied cell go unrendered.
    final covered = {for (final t in out) t.index};
    for (var i = 0; i < board.cells.length; i++) {
      if (board.cells[i] > 0 && !covered.contains(i)) {
        out.add(TileView(newId(), board.cells[i], i));
      }
    }
    return out;
  }

  /// Drops ghosts and clears the one-shot animation flags.
  static List<TileView> settle(List<TileView> tiles) => [
        for (final t in tiles)
          if (!t.isGhost) TileView(t.id, t.value, t.index),
      ];
}
