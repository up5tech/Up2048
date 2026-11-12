import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/difficulty.dart';
import '../domain/models/save_data.dart';

/// Local, offline persistence for saves, stats and settings (PLAN.md §16).
///
/// Abstract so controllers can be tested with an in-memory implementation.
abstract class StorageService {
  Settings loadSettings();
  Future<void> saveSettings(Settings s);

  DifficultyStats loadStats(Difficulty d);
  Future<void> saveStats(Difficulty d, DifficultyStats s);

  int loadCareerPoints();
  Future<void> saveCareerPoints(int points);

  SavedGame? loadGame(Difficulty d);
  Future<void> saveGame(SavedGame g);
  Future<void> clearGame(Difficulty d);

  /// Wipes saves, stats, career points and settings ("Reset data").
  Future<void> clearAll();

  static Future<StorageService> create() async =>
      _PrefsStorage(await SharedPreferences.getInstance());
}

class _PrefsStorage implements StorageService {
  final SharedPreferences _prefs;
  _PrefsStorage(this._prefs);

  static const _settingsKey = 'settings_v1';
  static const _careerKey = 'career_v1';

  @override
  Settings loadSettings() =>
      _readJson(_settingsKey, Settings.fromJson, Settings());

  @override
  Future<void> saveSettings(Settings s) =>
      _prefs.setString(_settingsKey, jsonEncode(s.toJson()));

  @override
  DifficultyStats loadStats(Difficulty d) => _readJson(
        'stats_v1_${d.name}',
        DifficultyStats.fromJson,
        DifficultyStats(),
      );

  @override
  Future<void> saveStats(Difficulty d, DifficultyStats s) =>
      _prefs.setString('stats_v1_${d.name}', jsonEncode(s.toJson()));

  @override
  int loadCareerPoints() => _prefs.getInt(_careerKey) ?? 0;

  @override
  Future<void> saveCareerPoints(int points) => _prefs.setInt(_careerKey, points);

  @override
  SavedGame? loadGame(Difficulty d) {
    final raw = _prefs.getString('game_v1_${d.name}');
    if (raw == null) return null;
    try {
      return SavedGame.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // corrupted → treat as no saved game
    }
  }

  @override
  Future<void> saveGame(SavedGame g) =>
      _prefs.setString('game_v1_${g.difficulty.name}', jsonEncode(g.toJson()));

  @override
  Future<void> clearGame(Difficulty d) => _prefs.remove('game_v1_${d.name}');

  @override
  Future<void> clearAll() async {
    final keys = [
      for (final k in _prefs.getKeys())
        if (k == _settingsKey ||
            k == _careerKey ||
            k.startsWith('game_v1_') ||
            k.startsWith('stats_v1_'))
          k,
    ];
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }

  T _readJson<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
    T fallback,
  ) {
    final raw = _prefs.getString(key);
    if (raw == null) return fallback;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return fallback;
    }
  }
}
