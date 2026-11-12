import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/game_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/stats_controller.dart';
import 'data/audio_service.dart';
import 'data/storage_service.dart';
import 'ui/screens/home_screen.dart';

class Up2048App extends StatelessWidget {
  final StorageService storage;
  final AudioService? audio;

  const Up2048App({super.key, required this.storage, this.audio});

  static const _seed = Color(0xFF4F9DB8);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController(storage)),
        ChangeNotifierProvider(create: (_) => StatsController(storage)),
        ChangeNotifierProvider(
          create: (ctx) => GameController(
            storage: storage,
            stats: ctx.read<StatsController>(),
            settings: ctx.read<SettingsController>(),
            audio: audio,
          ),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Up2048',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: _seed),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: _seed,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: settings.settings.darkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
