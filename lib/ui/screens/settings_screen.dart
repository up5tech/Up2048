import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_controller.dart';
import '../../controllers/stats_controller.dart';

/// Sound, haptics, theme, motion and data reset (PLAN.md §13.2).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(
    BuildContext context,
    SettingsController settings,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This deletes every saved game, all statistics and your settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final stats = context.read<StatsController>();
    await settings.storage.clearAll();
    settings.reset();
    stats.reset();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final settings = controller.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Sound effects'),
            value: settings.sound,
            onChanged: controller.setSound,
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Haptic feedback on merges and game over'),
            value: settings.vibration,
            onChanged: controller.setVibration,
          ),
          SwitchListTile(
            title: const Text('Dark mode'),
            value: settings.darkMode,
            onChanged: controller.setDarkMode,
          ),
          SwitchListTile(
            title: const Text('Reduce motion'),
            subtitle: const Text('Skip slide, merge and spawn animations'),
            value: settings.reduceMotion,
            onChanged: controller.setReduceMotion,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Reset data'),
            subtitle: const Text('Clear saves, statistics and settings'),
            onTap: () => _confirmReset(context, controller),
          ),
        ],
      ),
    );
  }
}
