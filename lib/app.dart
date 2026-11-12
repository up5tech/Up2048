import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/game_controller.dart';
import 'ui/screens/home_screen.dart';

class Up2048App extends StatelessWidget {
  const Up2048App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameController()),
      ],
      child: MaterialApp(
        title: 'Up2048',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: const Color(0xFF4F9DB8)),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
