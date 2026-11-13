import 'package:flutter/foundation.dart';

import '../data/storage_service.dart';
import '../domain/models/save_data.dart';

/// Sound, haptics, theme and motion preferences (PLAN.md §13.2).
class SettingsController extends ChangeNotifier {
  final StorageService storage;
  Settings settings;

  SettingsController(this.storage) : settings = storage.loadSettings();

  void setSound(bool value) => _update(() => settings.sound = value);

  void setVibration(bool value) => _update(() => settings.vibration = value);

  void setDarkMode(bool value) => _update(() => settings.darkMode = value);

  void setReduceMotion(bool value) =>
      _update(() => settings.reduceMotion = value);

  void setLocale(String value) => _update(() => settings.locale = value);

  /// Restores defaults (used by "Reset data").
  void reset() {
    settings = Settings();
    storage.saveSettings(settings);
    notifyListeners();
  }

  void _update(void Function() change) {
    change();
    storage.saveSettings(settings);
    notifyListeners();
  }
}
