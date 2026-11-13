# Up2048

An offline 2048-style number-merging puzzle built with Flutter. Four difficulty
levels are entirely data-driven and were balanced with a headless bot simulator.

- **100% offline:** no network packages, no `INTERNET` permission in release
  builds, all audio and artwork bundled in `assets/`.
- **Four levels:** Easy (5×5), Medium (classic 4×4), Hard (mean spawns, extra
  tiles), Very Hard (stones plus hostile spawns).
- **Features:** per-difficulty saves and stats, undo / hint / remove-tile with
  per-level limits, score multipliers, win + keep-going, animated tiles, dark
  mode, reduce motion, sound and haptics.
- **Languages:** English and Vietnamese, switchable in Settings and persisted.
- **Desktop/web:** arrow keys or WASD.

## Requirements

Flutter stable 3.47.x / Dart 3.13.x (see `pubspec.yaml`), plus the Android SDK
or Xcode for mobile builds.

## Getting started

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

`flutter pub get` regenerates `lib/l10n/app_localizations*.dart` from the ARB
catalogs (`generate: true` plus `l10n.yaml`). The generated files are committed
so a fresh clone analyses cleanly.

If `flutter test` fails while loading with `WebSocketException: Invalid
WebSocket upgrade request`, unset the local proxy variables first:

```bash
env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy flutter test
```

## Architecture

```
lib/
  domain/       pure Dart (never imports flutter/*): board, slide, spawner, evaluate, bot
  data/         SharedPreferences storage, audio
  controllers/  ChangeNotifier state
  ui/           screens and widgets
  core/         tile palette, difficulty styling
  l10n/         ARB catalogs and generated localizations
tool/simulate.dart   headless balancing simulator
```

Each level has one immutable `DifficultyConfig`; game logic never branches on
the `Difficulty` enum. `slide()` is a pure function returning `TileMotion`s
that drive `AnimatedPositioned` tiles. See `PLAN.md` for the full design.

## Difficulty tuning

Measured with expectimax depth 2, 100 games per level (`BALANCING.md`):

| Level | Win rate | Target |
|---|---|---|
| Easy | 100% | ≥95% |
| Medium | 46% | 60–85% (documented deviation) |
| Hard | 24% | 20–45% |
| Very Hard | 8% | 3–15% |

```bash
dart run tool/simulate.dart 100
dart run tool/simulate.dart 300 --bot=greedy
```

Human playtests are still pending: if bots and humans disagree, trust the
humans (`PLAN.md` §21.4).

## Localization

`lib/l10n/app_en.arb` and `app_vi.arb` are the source catalogs. Run
`flutter gen-l10n` after editing them; add a locale by adding an ARB file and
a choice in `SettingsScreen`.

## Artwork

All art is original CC0 work generated from the palette in `PLAN.md` §13.3.
Sources and licenses are recorded in `ASSETS_LICENSE.md`. Store artwork in
`assets/store/` is upload-only and is not bundled into the app.

Regenerate launcher and PWA icons after changing the source artwork:

```bash
dart run flutter_launcher_icons
```

## Release

`android/key.properties` and `android/upload-keystore.jks` are gitignored and
must never be committed. `android/app/build.gradle.kts` uses them when present
and falls back to the debug key for local builds. Create a production keystore
before publishing, then write `android/key.properties`:

```properties
storeFile=../upload-keystore.jks
keyAlias=up2048
storePassword=<your password>
keyPassword=<your password>
```

```bash
flutter build apk --release
flutter build appbundle --release
flutter build web --release
```

Artifacts: `build/app/outputs/flutter-apk/app-release.apk`,
`build/app/outputs/bundle/release/app-release.aab`, `build/web/`.

Verify the release is offline-capable and signed:

```bash
$ANDROID_HOME/build-tools/36.0.0/aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk
$ANDROID_HOME/build-tools/36.0.0/apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

When Android `cmdline-tools` is missing, `flutter build appbundle` prints a
non-fatal "failed to strip debug symbols" warning; the AAB is still written
and signed.

## Before a store release

- Run the manual test plan (`PLAN.md` §20.5), especially airplane mode on at
  least two real devices, rapid-swipe stress and tablet layouts.
- Run human playtests and decide whether Medium needs help.
- Capture real store screenshots and replace the local dev keystore with a
  production key.
