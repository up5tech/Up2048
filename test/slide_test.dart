import 'package:flutter_test/flutter_test.dart';
import 'package:up_2048/domain/models/board.dart';
import 'package:up_2048/domain/models/direction.dart';
import 'package:up_2048/domain/slide.dart';

/// Builds an n×n board whose first row is [r]; all other cells empty.
Board row(List<int> r) => Board(r.length, [
      ...r,
      for (var i = 0; i < r.length * (r.length - 1); i++) 0,
    ]);

/// Builds an n×n board whose first column is [c]; all other cells empty.
Board col(List<int> c) => Board(c.length, [
      for (var r = 0; r < c.length; r++) ...[
        c[r],
        for (var i = 1; i < c.length; i++) 0,
      ],
    ]);

List<int> firstRow(Board b) => b.cells.sublist(0, b.size);
List<int> firstCol(Board b) => [
      for (var r = 0; r < b.size; r++) b.cells[r * b.size],
    ];

void main() {
  group('slide left (first row of a 4x4)', () {
    test('[2,2,2,2] → [4,4,0,0]', () {
      expect(firstRow(slide(row([2, 2, 2, 2]), Direction.left).board),
          [4, 4, 0, 0]);
    });
    test('[2,2,2,0] → [4,2,0,0]', () {
      expect(firstRow(slide(row([2, 2, 2, 0]), Direction.left).board),
          [4, 2, 0, 0]);
    });
    test('[4,2,2,0] → [4,4,0,0]', () {
      expect(firstRow(slide(row([4, 2, 2, 0]), Direction.left).board),
          [4, 4, 0, 0]);
    });
    test('[2,0,2,4] → [4,4,0,0]', () {
      expect(firstRow(slide(row([2, 0, 2, 4]), Direction.left).board),
          [4, 4, 0, 0]);
    });
    test('a tile merges at most once per move: [4,2,2,4] → [4,4,4,0]', () {
      expect(firstRow(slide(row([4, 2, 2, 4]), Direction.left).board),
          [4, 4, 4, 0]);
    });
    test('no movement needed → moved is false', () {
      final r = slide(row([2, 4, 8, 16]), Direction.left);
      expect(r.moved, isFalse);
      expect(firstRow(r.board), [2, 4, 8, 16]);
    });
  });

  group('score and moved flag', () {
    test('gained equals sum of merged values', () {
      final r = slide(row([2, 2, 4, 4]), Direction.left);
      expect(r.gained, 12); // 4 + 8
    });
    test('pure slide without merge gains 0', () {
      final r = slide(row([2, 0, 4, 0]), Direction.left);
      expect(r.gained, 0);
      expect(r.moved, isTrue);
    });
  });

  group('motions', () {
    test('merge produces two merged motions to the same destination', () {
      final r = slide(row([2, 2, 0, 0]), Direction.left);
      expect(r.motions, hasLength(2));
      expect(r.motions.every((m) => m.merged && m.to == 0), isTrue);
      expect(r.motions.map((m) => m.from), containsAll([0, 1]));
    });
    test('non-merge motion records from → to', () {
      final r = slide(row([0, 0, 0, 8]), Direction.left);
      expect(r.motions, hasLength(1));
      expect(r.motions.single.from, 3);
      expect(r.motions.single.to, 0);
      expect(r.motions.single.merged, isFalse);
    });
  });

  group('blocked cells', () {
    test('tiles never cross a stone: [2,X,2,2] → [2,X,4,0]', () {
      final r = slide(row([2, kBlock, 2, 2]), Direction.left);
      expect(firstRow(r.board), [2, kBlock, 4, 0]);
    });
    test('stone at edge: [X,2,2,4] → [X,4,4,0]', () {
      final r = slide(row([kBlock, 2, 2, 4]), Direction.left);
      expect(firstRow(r.board), [kBlock, 4, 4, 0]);
    });
    test('canMove is false on a full board with no equal neighbours', () {
      // Checkerboard of 2s and 4s on (row + col) parity: every orthogonal
      // neighbour differs, board is full → no direction can change anything.
      final cells = <int>[
        for (var i = 0; i < 16; i++)
          ((i % 4) + (i ~/ 4)) % 2 == 0 ? 2 : 4,
      ];
      expect(canMove(Board(4, cells)), isFalse);
    });
  });

  group('other directions', () {
    test('slide up on first column matches slide left on first row', () {
      final up = slide(col([2, 2, 2, 2]), Direction.up);
      expect(firstCol(up.board), [4, 4, 0, 0]);
    });
    test('slide right packs to the right edge', () {
      final r = slide(row([0, 0, 2, 2]), Direction.right);
      expect(firstRow(r.board), [0, 0, 0, 4]);
      expect(r.gained, 4);
    });
    test('slide down packs to the bottom', () {
      final r = slide(col([0, 0, 2, 2]), Direction.down);
      expect(firstCol(r.board), [0, 0, 0, 4]);
    });
    test('up/down/left/right are consistent under transpose', () {
      // Column [2,0,2,4] sliding up == row [2,0,2,4] sliding left.
      final up = firstCol(slide(col([2, 0, 2, 4]), Direction.up).board);
      final left = firstRow(slide(row([2, 0, 2, 4]), Direction.left).board);
      expect(up, left);
    });
  });

  group('larger boards', () {
    test('5x5 slides correctly', () {
      final b = Board(5, List<int>.filled(25, 0)..[0] = 2 ..[1] = 2);
      final r = slide(b, Direction.left);
      expect(firstRow(r.board), [4, 0, 0, 0, 0]);
      expect(r.gained, 4);
    });
  });

  group('input board is not mutated', () {
    test('slide returns a new board', () {
      final b = row([2, 2, 0, 0]);
      final before = List<int>.of(b.cells);
      slide(b, Direction.left);
      expect(b.cells, before);
    });
  });
}
