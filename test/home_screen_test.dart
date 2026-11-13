import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:up_2048/app.dart';
import 'package:up_2048/data/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('home lists every difficulty with a play action',
      (tester) async {
    // Tall viewport so the lazy ListView attaches all four cards.
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final storage = await StorageService.create();
    await tester.pumpWidget(Up2048App(storage: storage));
    // The branded splash has a 700 ms minimum display before Home appears.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.text('Very Hard'), findsOneWidget);
    expect(find.text('Play'), findsNWidgets(4));
    expect(find.text('Not played yet'), findsNWidgets(4));
  });

  testWidgets('splash hands over to home after its minimum display',
      (tester) async {
    final storage = await StorageService.create();
    await tester.pumpWidget(Up2048App(storage: storage));
    expect(find.byKey(const ValueKey('splash_content')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('splash_content')), findsNothing);
    expect(find.text('Easy'), findsOneWidget);
  });

  testWidgets('reduce motion skips the splash', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings_v1':
          '{"sound":true,"vibration":true,"darkMode":false,"reduceMotion":true,"locale":"en"}',
    });
    final storage = await StorageService.create();
    await tester.pumpWidget(Up2048App(storage: storage));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('splash_content')), findsNothing);
    expect(find.text('Easy'), findsOneWidget);
  });
}
