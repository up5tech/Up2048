import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/audio_service.dart';
import 'data/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final storage = await StorageService.create();
  final audio = AudioService();
  // Bundled effects only; a failure here must never block startup.
  await audio.preload();

  runApp(Up2048App(storage: storage, audio: audio));
}
