import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum Sfx { slide, merge, spawn, win, gameOver }

/// Preloaded, bundled sound effects — never fetched from the network
/// (PLAN.md §17.2).
///
/// Every failure is contained: a missing or unsupported effect only means
/// that effect stays silent, never that a move throws.
class AudioService {
  static const Map<Sfx, String> _assets = {
    Sfx.slide: 'audio/slide.wav',
    Sfx.merge: 'audio/merge.wav',
    Sfx.spawn: 'audio/spawn.wav',
    Sfx.win: 'audio/win.wav',
    Sfx.gameOver: 'audio/game_over.wav',
  };

  final Map<Sfx, AudioPlayer> _players = {};
  bool _ready = false;

  /// Loads each effect into its own player. Safe to call repeatedly.
  Future<void> preload() async {
    if (_ready) return;
    for (final entry in _assets.entries) {
      try {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(entry.value));
        _players[entry.key] = player;
      } catch (e) {
        debugPrint('AudioService: ${entry.value} unavailable ($e)');
      }
    }
    _ready = true;
  }

  /// Plays [sfx] from the start. No-op when the effect failed to load.
  Future<void> play(Sfx sfx) async {
    final player = _players[sfx];
    if (player == null) return;
    try {
      await player.stop();
      await player.resume();
    } catch (e) {
      debugPrint('AudioService: could not play ${sfx.name} ($e)');
    }
  }

  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _ready = false;
  }
}
