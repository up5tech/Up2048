import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/stats_controller.dart';
import '../../domain/models/difficulty.dart';
import '../widgets/difficulty_card.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

/// Difficulty selection screen (PLAN.md §13.2).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _openGame(Difficulty difficulty, {required bool resume}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(difficulty: difficulty, resume: resume),
      ),
    );
    // Saved-game state and best scores changed while we were away.
    if (mounted) setState(() {});
  }

  Future<void> _openScreen(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stats = context.watch<StatsController>();
    final game = context.read<GameController>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              children: [
                const Text(
                  'Up2048',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Swipe to slide and merge tiles. Pick a difficulty.',
                  style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                for (final d in Difficulty.values) ...[
                  DifficultyCard(
                    cfg: kDifficulties[d]!,
                    bestScore: stats.statsFor(d).bestScore,
                    bestTile: stats.statsFor(d).bestTile,
                    hasSave: game.hasSavedGame(d),
                    onNewGame: () => _openGame(d, resume: false),
                    onContinue: () => _openGame(d, resume: true),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openScreen(const StatsScreen()),
                      icon: const Icon(Icons.bar_chart, size: 18),
                      label: const Text('Stats'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openScreen(const SettingsScreen()),
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('Settings'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openScreen(const HowToPlayScreen()),
                      icon: const Icon(Icons.help_outline, size: 18),
                      label: const Text('How to play'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
