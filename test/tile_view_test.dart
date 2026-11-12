import 'package:flutter_test/flutter_test.dart';
import 'package:up_2048/domain/models/board.dart';
import 'package:up_2048/domain/models/direction.dart';
import 'package:up_2048/domain/models/tile_view.dart';
import 'package:up_2048/domain/slide.dart';

Board boardWith(Map<int, int> cells) {
  final out = List<int>.filled(16, 0);
  cells.forEach((i, v) => out[i] = v);
  return Board(4, out);
}

void main() {
  test('fromBoard skips empty cells and gives unique ids', () {
    final tiles = TileView.fromBoard(boardWith({0: 2, 5: 4}));
    expect(tiles.map((t) => t.value), [2, 4]);
    expect(tiles.map((t) => t.index), [0, 5]);
    expect(tiles.map((t) => t.id).toSet(), hasLength(2));
  });

  test('a sliding tile keeps its id', () {
    final b = boardWith({3: 2});
    final tiles = TileView.fromBoard(b);
    final r = slide(b, Direction.left);
    final next = TileView.applyMove(tiles, r.motions, r.board, const []);

    expect(next, hasLength(1));
    expect(next.single.id, tiles.single.id);
    expect(next.single.index, 0);
    expect(next.single.value, 2);
    expect(next.single.isMerged, isFalse);
  });

  test('a merge yields two ghosts plus a new merged tile on top', () {
    final b = boardWith({2: 2, 3: 2});
    final tiles = TileView.fromBoard(b);
    final oldIds = tiles.map((t) => t.id).toSet();
    final r = slide(b, Direction.left);
    final next = TileView.applyMove(tiles, r.motions, r.board, const []);

    final ghosts = next.where((t) => t.isGhost).toList();
    final merged = next.where((t) => t.isMerged).toList();

    expect(ghosts, hasLength(2));
    expect(ghosts.every((t) => t.index == 0 && t.value == 2), isTrue);
    expect(ghosts.map((t) => t.id).toSet(), oldIds);

    expect(merged, hasLength(1));
    expect(merged.single.index, 0);
    expect(merged.single.value, 4);
    expect(oldIds.contains(merged.single.id), isFalse);
  });

  test('spawned cells become isNew tiles', () {
    final b = boardWith({3: 2});
    final tiles = TileView.fromBoard(b);
    final r = slide(b, Direction.left);
    final spawned = r.board.withCell(15, 4);
    final next = TileView.applyMove(tiles, r.motions, spawned, const [15]);

    final fresh = next.where((t) => t.isNew).toList();
    expect(fresh, hasLength(1));
    expect(fresh.single.index, 15);
    expect(fresh.single.value, 4);
  });

  test('settle drops ghosts and clears one-shot flags', () {
    const tiles = [
      TileView(1, 2, 0, isGhost: true),
      TileView(2, 4, 0, isMerged: true),
      TileView(3, 8, 5, isNew: true),
    ];
    final settled = TileView.settle(tiles);

    expect(settled.map((t) => t.id), [2, 3]);
    expect(settled.every((t) => !t.isGhost && !t.isNew && !t.isMerged), isTrue);
  });

  test('a stale tile list still renders every occupied cell', () {
    final b = boardWith({0: 2, 5: 4});
    final r = slide(b, Direction.right);
    final next = TileView.applyMove(const [], r.motions, r.board, const []);

    expect(next.map((t) => t.index).toSet(), {3, 7});
    expect(next.map((t) => t.value).toSet(), {2, 4});
  });
}
