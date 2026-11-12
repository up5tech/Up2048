import 'package:flutter/foundation.dart';

import '../data/storage_service.dart';
import '../domain/models/difficulty.dart';
import '../domain/models/save_data.dart';

/// Per-difficulty statistics, best scores and career points (PLAN.md §18).
class StatsController extends ChangeNotifier {
  final StorageService storage;
  final Map<Difficulty, DifficultyStats> _stats = {};
  int careerPoints;

  StatsController(this.storage) : careerPoints = storage.loadCareerPoints() {
    for (final d in Difficulty.values) {
      _stats[d] = storage.loadStats(d);
    }
  }

  DifficultyStats statsFor(Difficulty d) => _stats[d]!;

  /// A game counts as played when it starts.
  void onGameStarted(Difficulty d) {
    _stats[d]!.gamesPlayed += 1;
    _persist(d);
  }

  /// Counted once, when the target tile is first reached.
  void onWin(Difficulty d) {
    _stats[d]!.wins += 1;
    _persist(d);
  }

  /// Best score/tile update continuously, so quitting mid-game keeps credit.
  void recordBest(
    Difficulty d, {
    required int score,
    required int bestTile,
  }) {
    final s = _stats[d]!;
    var changed = false;
    if (score > s.bestScore) {
      s.bestScore = score;
      changed = true;
    }
    if (bestTile > s.bestTile) {
      s.bestTile = bestTile;
      changed = true;
    }
    if (changed) _persist(d);
  }

  /// Adds career points: finalScore × the difficulty's multiplier.
  void onGameFinished(
    Difficulty d, {
    required int score,
    required int bestTile,
    required int moves,
  }) {
    recordBest(d, score: score, bestTile: bestTile);
    _stats[d]!.totalMoves += moves;
    careerPoints += (score * kDifficulties[d]!.scoreMultiplier).round();
    storage.saveCareerPoints(careerPoints);
    _persist(d);
  }

  /// Wipes every record (used by "Reset data").
  void reset() {
    for (final d in Difficulty.values) {
      _stats[d] = DifficultyStats();
      storage.saveStats(d, _stats[d]!);
    }
    careerPoints = 0;
    storage.saveCareerPoints(0);
    notifyListeners();
  }

  void _persist(Difficulty d) {
    storage.saveStats(d, _stats[d]!);
    notifyListeners();
  }
}
