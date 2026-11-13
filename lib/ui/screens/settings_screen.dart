import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_controller.dart';
import '../../controllers/stats_controller.dart';
import '../../l10n/app_localizations.dart';

/// Sound, haptics, theme, motion and data reset (PLAN.md §13.2).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(
    BuildContext context,
    SettingsController settings,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetConfirmTitle),
        content: Text(l10n.resetConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.reset),
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l10n.soundEffects),
            value: settings.sound,
            onChanged: controller.setSound,
          ),
          SwitchListTile(
            title: Text(l10n.vibration),
            subtitle: Text(l10n.vibrationSubtitle),
            value: settings.vibration,
            onChanged: controller.setVibration,
          ),
          SwitchListTile(
            title: Text(l10n.darkMode),
            value: settings.darkMode,
            onChanged: controller.setDarkMode,
          ),
          SwitchListTile(
            title: Text(l10n.reduceMotion),
            subtitle: Text(l10n.reduceMotionSubtitle),
            value: settings.reduceMotion,
            onChanged: controller.setReduceMotion,
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              value: settings.locale,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text(l10n.languageEnglish),
                ),
                DropdownMenuItem(
                  value: 'vi',
                  child: Text(l10n.languageVietnamese),
                ),
              ],
              onChanged: (v) {
                if (v != null) controller.setLocale(v);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.resetData),
            subtitle: Text(l10n.resetDataSubtitle),
            onTap: () => _confirmReset(context, controller),
          ),
        ],
      ),
    );
  }
}
