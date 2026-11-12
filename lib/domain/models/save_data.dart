import 'difficulty.dart';

class DifficultyStats {
  int gamesPlayed;
  int wins;
  int bestScore;
  int bestTile;
  int totalMoves;
  DifficultyStats({
    this.gamesPlayed = 0,
    this.wins = 0,
    this.bestScore = 0,
    this.bestTile = 0,
    this.totalMoves = 0,
  });

  Map<String, dynamic> toJson() => {
        'played': gamesPlayed,
        'wins': wins,
        'bestScore': bestScore,
        'bestTile': bestTile,
        'moves': totalMoves,
      };

  factory DifficultyStats.fromJson(Map<String, dynamic> j) => DifficultyStats(
        gamesPlayed: j['played'] ?? 0,
        wins: j['wins'] ?? 0,
        bestScore: j['bestScore'] ?? 0,
        bestTile: j['bestTile'] ?? 0,
        totalMoves: j['moves'] ?? 0,
      );
}

class Settings {
  bool sound;
  bool vibration;
  bool darkMode;
  bool reduceMotion;
  String locale; // 'en' | 'vi'
  Settings({
    this.sound = true,
    this.vibration = true,
    this.darkMode = false,
    this.reduceMotion = false,
    this.locale = 'en',
  });

  Map<String, dynamic> toJson() => {
        'sound': sound,
        'vibration': vibration,
        'darkMode': darkMode,
        'reduceMotion': reduceMotion,
        'locale': locale,
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        sound: j['sound'] ?? true,
        vibration: j['vibration'] ?? true,
        darkMode: j['darkMode'] ?? false,
        reduceMotion: j['reduceMotion'] ?? false,
        locale: j['locale'] ?? 'en',
      );
}

/// A saved, unfinished game for one difficulty.
class SavedGame {
  final Difficulty difficulty;
  final int size;
  final List<int> cells;
  final int score;
  final int moves;
  final int undoLeft;
  final int hintsLeft;
  final int removeLeft;
  final bool keepPlaying; // player chose "Keep going" after winning

  SavedGame({
    required this.difficulty,
    required this.size,
    required this.cells,
    required this.score,
    required this.moves,
    required this.undoLeft,
    required this.hintsLeft,
    required this.removeLeft,
    required this.keepPlaying,
  });

  Map<String, dynamic> toJson() => {
        'd': difficulty.name,
        'size': size,
        'cells': cells,
        'score': score,
        'moves': moves,
        'undo': undoLeft,
        'hints': hintsLeft,
        'remove': removeLeft,
        'keep': keepPlaying,
      };

  factory SavedGame.fromJson(Map<String, dynamic> j) => SavedGame(
        difficulty: Difficulty.values.byName(j['d'] as String),
        size: j['size'] as int,
        cells: (j['cells'] as List).cast<int>().toList(),
        score: j['score'] as int,
        moves: j['moves'] as int,
        undoLeft: j['undo'] as int,
        hintsLeft: j['hints'] as int,
        removeLeft: j['remove'] as int,
        keepPlaying: j['keep'] ?? false,
      );
}
