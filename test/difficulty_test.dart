import 'package:flutter_test/flutter_test.dart';
import 'package:up_2048/domain/models/difficulty.dart';

bool _isPowerOfTwo(int v) => v > 0 && (v & (v - 1)) == 0;

void main() {
  test('all four difficulties are defined', () {
    expect(kDifficulties.keys, containsAll(Difficulty.values));
    expect(kDifficulties.length, Difficulty.values.length);
  });

  for (final d in Difficulty.values) {
    final cfg = kDifficulties[d]!;
    group(d.name, () {
      test('board size is sane', () {
        expect(cfg.boardSize, inInclusiveRange(3, 8));
        expect(cfg.boardSize * cfg.boardSize, greaterThan(cfg.initialTiles));
      });

      test('spawn table is valid', () {
        expect(cfg.spawnTable, isNotEmpty);
        for (final w in cfg.spawnTable) {
          expect(w.weight, greaterThan(0));
          expect(_isPowerOfTwo(w.value), isTrue);
        }
      });

      test('target tile is a power of two', () {
        expect(_isPowerOfTwo(cfg.targetTile), isTrue);
      });

      test('initial tiles fit on the board', () {
        expect(cfg.initialTiles, greaterThan(0));
        final maxStones = cfg.blockedLayouts.isEmpty
            ? 0
            : cfg.blockedLayouts.first.length;
        expect(cfg.initialTiles + maxStones,
            lessThanOrEqualTo(cfg.boardSize * cfg.boardSize));
      });

      test('adversary strength is in [0, 1]', () {
        expect(cfg.adversaryStrength, inInclusiveRange(0.0, 1.0));
      });

      test('power-up limits are sane', () {
        expect(cfg.undoLimit, greaterThanOrEqualTo(-1));
        expect(cfg.hintLimit, greaterThanOrEqualTo(0));
        expect(cfg.removeTileLimit, greaterThanOrEqualTo(0));
      });

      test('double spawn interval is non-negative', () {
        expect(cfg.doubleSpawnEvery, greaterThanOrEqualTo(0));
      });

      test('score multiplier is positive', () {
        expect(cfg.scoreMultiplier, greaterThan(0));
      });
    });

    group('${d.name} blocked layouts', () {
      test('indices are valid, non-corner, non-adjacent', () {
        final n = cfg.boardSize;
        final corners = {0, n - 1, n * (n - 1), n * n - 1};
        for (final layout in cfg.blockedLayouts) {
          expect(layout.length, greaterThanOrEqualTo(1));
          for (final i in layout) {
            expect(i, inInclusiveRange(0, n * n - 1));
            expect(corners.contains(i), isFalse, reason: 'stone in corner');
          }
          // pairwise non-adjacent (orthogonal)
          for (var a = 0; a < layout.length; a++) {
            for (var b = a + 1; b < layout.length; b++) {
              final ra = layout[a] ~/ n, ca = layout[a] % n;
              final rb = layout[b] ~/ n, cb = layout[b] % n;
              final adjacent = (ra - rb).abs() + (ca - cb).abs() == 1;
              expect(adjacent, isFalse,
                  reason: 'adjacent stones at ${layout[a]}, ${layout[b]}');
            }
          }
        }
      });
    });
  }

  test('difficulty ordering: harder levels are at least as hostile', () {
    final easy = kDifficulties[Difficulty.easy]!;
    final medium = kDifficulties[Difficulty.medium]!;
    final hard = kDifficulties[Difficulty.hard]!;
    final veryHard = kDifficulties[Difficulty.veryHard]!;

    // Adversary strength must be non-decreasing.
    expect(easy.adversaryStrength <= medium.adversaryStrength, isTrue);
    expect(medium.adversaryStrength <= hard.adversaryStrength, isTrue);
    expect(hard.adversaryStrength <= veryHard.adversaryStrength, isTrue);

    // Help (undo+hints+remove) should shrink as difficulty grows.
    int help(DifficultyConfig c) =>
        c.undoLimit.clamp(0, 99) + c.hintLimit + c.removeTileLimit;
    expect(help(easy), greaterThanOrEqualTo(help(medium)));
    expect(help(medium), greaterThanOrEqualTo(help(hard)));
    expect(help(hard), greaterThanOrEqualTo(help(veryHard)));
  });
}
