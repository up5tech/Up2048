// Headless balancing simulator (PLAN.md §21).
//
// Usage:
//   dart run tool/simulate.dart                      # 100 games, expectimax depth 2
//   dart run tool/simulate.dart 500 --bot=greedy     # fast casual-player proxy
//   dart run tool/simulate.dart 200 --bot=random     # sanity check
//   dart run tool/simulate.dart 40 --difficulty=hard,veryHard
//
// Bots:
//   random     — random valid move (should almost never win)
//   greedy     — best evaluate() after one slide (casual/decent player proxy)
//   expectimax — depth-2 search (skilled player proxy, slow)

import 'dart:io';
import 'dart:math';

import 'package:up_2048/domain/evaluate.dart';
import 'package:up_2048/domain/expectimax_bot.dart';
import 'package:up_2048/domain/models/board.dart';
import 'package:up_2048/domain/models/difficulty.dart';
import 'package:up_2048/domain/models/direction.dart';
import 'package:up_2048/domain/slide.dart';
import 'package:up_2048/domain/spawner.dart';

enum BotKind { random, greedy, expectimax }

/// Win-rate target ranges from PLAN.md §21.3 (expectimax depth 2).
const Map<Difficulty, (double, double)> kTargets = {
  Difficulty.easy: (95, 100),
  Difficulty.medium: (60, 85),
  Difficulty.hard: (20, 45),
  Difficulty.veryHard: (3, 15),
};

class BotStats {
  int games = 0;
  int wins = 0;
  int totalScore = 0;
  int totalMoves = 0;
  int totalMaxTile = 0;

  double get winRate => games == 0 ? 0 : 100 * wins / games;
  int get avgScore => games == 0 ? 0 : totalScore ~/ games;
  int get avgMoves => games == 0 ? 0 : totalMoves ~/ games;
  int get avgMaxTile => games == 0 ? 0 : totalMaxTile ~/ games;
}

/// Plays one full game and folds the outcome into [out].
void playGame(
  DifficultyConfig cfg,
  int seed,
  BotKind kind,
  int depth,
  int samples,
  BotStats out,
) {
  final rng = Random(seed);
  final spawner = Spawner(cfg, rng);
  final bot = ExpectimaxBot(
    depth: depth,
    maxChanceSamples: samples,
    rng: rng,
  );
  var board = createInitialBoard(cfg, rng);
  var score = 0;
  var moves = 0;
  var won = false;

  // Hard stop: a runaway game should never hang the simulator.
  while (moves < 20000) {
    final dir = switch (kind) {
      BotKind.random => _randomMove(board, rng),
      BotKind.greedy => _greedyMove(board),
      BotKind.expectimax => bot.bestMove(board, cfg.spawnTable),
    };
    if (dir == null) break; // no move: game over

    final r = slide(board, dir);
    board = r.board;
    score += r.gained;
    moves++;

    final spawns = 1 +
        ((cfg.doubleSpawnEvery > 0 && moves % cfg.doubleSpawnEvery == 0)
            ? 1
            : 0);
    for (var i = 0; i < spawns; i++) {
      final s = spawner.spawn(board);
      if (s == null) break;
      board = s.board;
    }

    if (board.maxTile >= cfg.targetTile) {
      won = true;
      break;
    }
  }

  out.games++;
  if (won) out.wins++;
  out.totalScore += score;
  out.totalMoves += moves;
  out.totalMaxTile += board.maxTile;
}

Direction? _randomMove(Board b, Random rng) {
  final valid = [
    for (final d in Direction.values)
      if (slide(b, d).moved) d,
  ];
  if (valid.isEmpty) return null;
  return valid[rng.nextInt(valid.length)];
}

Direction? _greedyMove(Board b) {
  Direction? best;
  var bestScore = double.negativeInfinity;
  for (final d in Direction.values) {
    final r = slide(b, d);
    if (!r.moved) continue;
    final s = evaluate(r.board);
    if (s > bestScore) {
      bestScore = s;
      best = d;
    }
  }
  return best;
}

void main(List<String> args) {
  final positional = [for (final a in args) if (!a.startsWith('--')) a];
  final flags = <String, String>{};
  for (final a in args) {
    if (!a.startsWith('--')) continue;
    final i = a.indexOf('=');
    if (i < 0) {
      flags[a.substring(2)] = 'true';
    } else {
      flags[a.substring(2, i)] = a.substring(i + 1);
    }
  }

  final games = positional.isNotEmpty ? int.parse(positional.first) : 100;
  final kind = BotKind.values.firstWhere(
    (k) => k.name == flags['bot'],
    orElse: () => BotKind.expectimax,
  );
  final depth = int.tryParse(flags['depth'] ?? '') ?? 2;
  final samples = int.tryParse(flags['samples'] ?? '') ?? 6;
  final only = flags['difficulty']?.split(',').toSet();

  stdout.writeln(
    'Up2048 simulation — bot=${kind.name}, depth=$depth, '
    'samples=$samples, games=$games\n',
  );
  stdout.writeln(
    '${'level'.padRight(11)}${'win%'.padLeft(7)}${'avgScore'.padLeft(11)}'
    '${'avgMoves'.padLeft(10)}${'avgMax'.padLeft(9)}${'elapsed'.padLeft(10)}  target',
  );

  final rates = <Difficulty, double>{};
  for (final cfg in kDifficulties.values) {
    if (only != null && !only.contains(cfg.id.name)) continue;

    final watch = Stopwatch()..start();
    final stats = BotStats();
    for (var g = 0; g < games; g++) {
      playGame(cfg, g, kind, depth, samples, stats);
    }
    watch.stop();
    rates[cfg.id] = stats.winRate;

    final (lo, hi) = kTargets[cfg.id]!;
    final inside = stats.winRate >= lo && stats.winRate <= hi;
    stdout.writeln(
      '${cfg.label.padRight(11)}'
      '${stats.winRate.toStringAsFixed(1).padLeft(7)}'
      '${stats.avgScore.toString().padLeft(11)}'
      '${stats.avgMoves.toString().padLeft(10)}'
      '${stats.avgMaxTile.toString().padLeft(9)}'
      '${'${watch.elapsed.inSeconds}s'.padLeft(10)}'
      '  ${lo.toStringAsFixed(0)}-${hi.toStringAsFixed(0)}% '
      '${inside ? 'ok' : 'OUTSIDE'}',
    );
  }

  // Ordering must hold: Easy > Medium > Hard > Very Hard (PLAN.md §21.3).
  if (rates.length == Difficulty.values.length) {
    final spread = rates.values.reduce(max) - rates.values.reduce(min);
    if (spread < 1.0) {
      stdout.writeln(
        '\nOrdering check skipped: every level landed within 1 point of the '
        'others, so this bot cannot separate them.',
      );
    } else {
      final ordered = rates[Difficulty.easy]! > rates[Difficulty.medium]! &&
          rates[Difficulty.medium]! > rates[Difficulty.hard]! &&
          rates[Difficulty.hard]! > rates[Difficulty.veryHard]!;
      stdout.writeln(
        '\nOrdering Easy > Medium > Hard > Very Hard: '
        '${ordered ? 'ok' : 'VIOLATED'}',
      );
    }
  }
}
