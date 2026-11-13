import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:up_2048/app.dart';
import 'package:up_2048/controllers/settings_controller.dart';
import 'package:up_2048/data/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const vietnameseSettings = {
    'sound': true,
    'vibration': true,
    'darkMode': false,
    'reduceMotion': true,
    'locale': 'vi',
  };

  testWidgets('a saved Vietnamese locale renders the Vietnamese catalog',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_v1': jsonEncode(vietnameseSettings),
    });
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final storage = await StorageService.create();
    await tester.pumpWidget(Up2048App(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Dễ'), findsOneWidget);
    expect(find.text('Trung bình'), findsOneWidget);
    expect(find.text('Khó'), findsOneWidget);
    expect(find.text('Rất khó'), findsOneWidget);
    expect(find.text('Cài đặt'), findsOneWidget);
  });

  test('locale changes are persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final controller = SettingsController(storage);

    expect(controller.settings.locale, 'en');
    controller.setLocale('vi');
    await Future<void>.delayed(Duration.zero);

    expect(controller.settings.locale, 'vi');
    expect((await StorageService.create()).loadSettings().locale, 'vi');
  });
}
