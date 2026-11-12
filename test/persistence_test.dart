import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:up_2048/controllers/game_controller.dart';
import 'package:up_2048/controllers/settings_controller.dart';
import 'package:up_2048/controllers/stats_controller.dart';
import 'package:up_2048/data/storage_service.dart';
import 'package:up_2048/domain/models/difficulty.dart';
import 'package:up_2048/domain/models/direction.dart';

/// Plays the first direction that changes the board.
Future<bool> playAnyMove(GameController g) async {
  for (final d in Direction.values) {
    final before = List<int>.of(g.board.cells);
    await g.swipe(d);
    if (g.board.cells.join() != before.join()) return true;
  }
  return false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('settings survive a reload', () async {
    final storage = await StorageService.create();
    final controller = SettingsController(storage);
    controller.setDarkMode(true);
    controller.setReduceMotion(true);
    controller.setSound(false);

    final reloaded = SettingsController(await StorageService.create());
    expect(reloaded.settings.darkMode, isTrue);
    expect(reloaded.settings.reduceMotion, isTrue);
    expect(reloaded.settings.sound, isFalse);
  });

  test('each difficulty keeps its own saved game', () async {
    final storage = await StorageService.create();
    final stats = StatsController(storage);
    final settings = SettingsController(storage);

    final hard = GameController(
      storage: storage,
      stats: stats,
      settings: settings,
    );
    hard.newGame(Difficulty.hard, seed: 3);
    expect(await playAnyMove(hard), isTrue);
    final cells = List<int>.of(hard.board.cells);
    final score = hard.score;
    final moves = hard.moves;
    await hard.saveNow();

    final easy = GameController(storage: storage, stats: stats);
    easy.newGame(Difficulty.easy, seed: 4);
    await easy.saveNow();

    final resumed = GameController(storage: storage, stats: stats);
    expect(resumed.hasSavedGame(Difficulty.hard), isTrue);
    resumed.resume(Difficulty.hard);
    expect(resumed.board.cells, cells);
    expect(resumed.score, score);
    expect(resumed.moves, moves);
    expect(resumed.status, GameStatus.playing);

    // Resuming Hard leaves the Easy slot alone.
    expect(storage.loadGame(Difficulty.easy), isNotNull);
  });

  test('a corrupted save is ignored and resume starts a new game', () async {
    SharedPreferences.setMockInitialValues({'game_v1_medium': '{not json'});
    final storage = await StorageService.create();
    expect(storage.loadGame(Difficulty.medium), isNull);

    final game = GameController(storage: storage);
    game.resume(Difficulty.medium);
    expect(game.moves, 0);
    expect(game.score, 0);
    expect(game.status, GameStatus.playing);
    expect(game.board.cells.where((v) => v > 0).length, 2);
  });

  test('a finished game clears its save', () async {
    final storage = await StorageService.create();
    final game = GameController(storage: storage);
    game.newGame(Difficulty.medium, seed: 5);
    await game.saveNow();
    expect(storage.loadGame(Difficulty.medium), isNotNull);

    game.status = GameStatus.over;
    await game.saveNow();
    expect(storage.loadGame(Difficulty.medium), isNull);
  });

  test('wins, best score and career points are recorded once', () async {
    final storage = await StorageService.create();
    final stats = StatsController(storage);

    stats.onGameStarted(Difficulty.medium);
    stats.onWin(Difficulty.medium);
    stats.onGameFinished(
      Difficulty.medium,
      score: 100,
      bestTile: 64,
      moves: 40,
    );

    final medium = stats.statsFor(Difficulty.medium);
    expect(medium.gamesPlayed, 1);
    expect(medium.wins, 1);
    expect(medium.bestScore, 100);
    expect(medium.bestTile, 64);
    expect(medium.totalMoves, 40);
    expect(stats.careerPoints, 100); // Medium multiplier is ×1

    final reloaded = StatsController(storage);
    expect(reloaded.statsFor(Difficulty.medium).bestScore, 100);
    expect(reloaded.careerPoints, 100);
  });

  test('reset data wipes saves, stats and settings', () async {
    final storage = await StorageService.create();
    final settings = SettingsController(storage);
    final stats = StatsController(storage);
    final game = GameController(storage: storage, stats: stats, settings: settings);

    game.newGame(Difficulty.medium, seed: 7);
    await game.saveNow();
    settings.setDarkMode(true);
    stats.onWin(Difficulty.medium);
    expect(storage.loadGame(Difficulty.medium), isNotNull);

    await settings.storage.clearAll();
    settings.reset();
    stats.reset();

    expect(storage.loadGame(Difficulty.medium), isNull);
    expect(stats.statsFor(Difficulty.medium).wins, 0);
    expect(stats.careerPoints, 0);
    expect(settings.settings.darkMode, isFalse);
  });
}
