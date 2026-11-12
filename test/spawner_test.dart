import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:up_2048/domain/evaluate.dart';
import 'package:up_2048/domain/models/board.dart';
import 'package:up_2048/domain/models/difficulty.dart';
import 'package:up_2048/domain/spawner.dart';

void main() {
  group('sampleValue', () {
    test('distribution matches weights within tolerance', () {
      const table = [SpawnWeight(2, 90), SpawnWeight(4, 10)];
      final rng = Random(42);
      var twos = 0;
      const draws = 100000;
      for (var i = 0; i < draws; i++) {
        if (sampleValue(table, rng) == 2) twos++;
      }
      final ratio = twos / draws;
      expect(ratio, closeTo(0.9, 0.01));
    });

    test('single-entry table always returns that value', () {
      final rng = Random(1);
      const table = [SpawnWeight(8, 1)];
      for (var i = 0; i < 100; i++) {
        expect(sampleValue(table, rng), 8);
      }
    });
  });

  group('Spawner', () {
    const cfg = DifficultyConfig(
      id: Difficulty.medium,
      label: 'Test',
      boardSize: 4,
      targetTile: 2048,
      spawnTable: [SpawnWeight(2, 90), SpawnWeight(4, 10)],
      initialTiles: 2,
      undoLimit: 0,
      hintLimit: 0,
      removeTileLimit: 0,
      scoreMultiplier: 1,
    );

    const brutal = DifficultyConfig(
      id: Difficulty.veryHard,
      label: 'Brutal',
      boardSize: 4,
      targetTile: 1024,
      spawnTable: [SpawnWeight(2, 1)],
      initialTiles: 4,
      adversaryStrength: 1,
      undoLimit: 0,
      hintLimit: 0,
      removeTileLimit: 0,
      scoreMultiplier: 2,
    );

    test('spawn fills an empty cell with a table value', () {
      final rng = Random(7);
      final spawner = Spawner(cfg, rng);
      final board = Board.empty(4);
      final r = spawner.spawn(board)!;
      expect(r.board.cells[r.index], r.value);
      expect(cfg.spawnTable.map((w) => w.value), contains(r.value));
      expect(board.emptyIndices, hasLength(16)); // input untouched
    });

    test('returns null on a full board', () {
      final rng = Random(7);
      final spawner = Spawner(cfg, rng);
      final full = Board(4, List<int>.filled(16, 2));
      expect(spawner.spawn(full), isNull);
    });

    test('spawns into the only empty cell when board is nearly full', () {
      final rng = Random(7);
      final spawner = Spawner(brutal, rng);
      final cells = List<int>.filled(16, 2);
      cells[5] = 0;
      final r = spawner.spawn(Board(4, cells))!;
      expect(r.index, 5);
      expect(r.value, 2);
    });

    test('adversary picks the cell with the lowest evaluate()', () {
      // Full board of 2s except two empty cells: corner 0 vs centre 5.
      // Placing at the centre creates more mergeable neighbours → higher
      // evaluate → better for the player → adversary must avoid it.
      final cells = List<int>.filled(16, 2);
      cells[0] = 0;
      cells[5] = 0;
      final b = Board(4, cells);

      final cornerScore = evaluate(b.withCell(0, 2));
      final centreScore = evaluate(b.withCell(5, 2));
      expect(cornerScore, isNot(centreScore)); // sanity: distinct candidates

      final expected = cornerScore < centreScore ? 0 : 5;
      final rng = Random(11);
      final spawner = Spawner(brutal, rng);
      final r = spawner.spawn(b)!;
      expect(r.index, expected);
    });

    test('adversaryStrength = 0 never consults evaluate (random cell)',
        () {
      // With strength 0 the pick is uniform over empties; run many trials on
      // a 1-empty-cell board is trivial, so instead verify both empty cells
      // are reachable across seeds (no deterministic worst-cell bias).
      final seen = <int>{};
      for (var seed = 0; seed < 50; seed++) {
        final cells = List<int>.filled(16, 2);
        cells[0] = 0;
        cells[5] = 0;
        final rng = Random(seed);
        final spawner = Spawner(cfg, rng); // adversaryStrength = 0
        seen.add(spawner.spawn(Board(4, cells))!.index);
      }
      expect(seen, containsAll([0, 5]));
    });
  });

  group('createInitialBoard', () {
    for (final d in Difficulty.values) {
      test('${d.name}: correct size, tile count, spawn values', () {
        final cfg = kDifficulties[d]!;
        final rng = Random(99);
        final b = createInitialBoard(cfg, rng);
        expect(b.size, cfg.boardSize);
        expect(b.cells, hasLength(cfg.boardSize * cfg.boardSize));

        final values = cfg.spawnTable.map((w) => w.value).toSet();
        final tiles = b.cells.where((v) => v > 0).toList();
        final blocks = b.cells.where((v) => v == -1).length;
        expect(tiles.length, cfg.initialTiles);
        expect(
            blocks, cfg.blockedLayouts.isEmpty ? 0 : cfg.blockedLayouts.first.length);
        for (final t in tiles) {
          expect(values, contains(t));
        }
      });
    }

    test('veryHard: stones are never in a corner', () {
      final cfg = kDifficulties[Difficulty.veryHard]!;
      const corners = {0, 3, 12, 15};
      for (final layout in cfg.blockedLayouts) {
        for (final i in layout) {
          expect(corners.contains(i), isFalse);
        }
      }
    });

    test('same seed produces identical boards', () {
      final cfg = kDifficulties[Difficulty.hard]!;
      final a = createInitialBoard(cfg, Random(123));
      final b = createInitialBoard(cfg, Random(123));
      expect(a.cells, b.cells);
    });
  });
}
