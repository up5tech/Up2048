import 'package:flutter/material.dart';

class Up2048App extends StatelessWidget {
  const Up2048App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Up2048',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F9DB8)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Up2048')),
      ),
    );
  }
}
