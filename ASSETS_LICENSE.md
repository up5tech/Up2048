# Asset licenses

All assets ship inside the app; nothing is downloaded at runtime.

## Audio — `assets/audio/`

| File | Source | License |
|---|---|---|
| `slide.wav` | Generated for Up2048 (synthesised sine tone) | CC0 / public domain |
| `merge.wav` | Generated for Up2048 (synthesised sine tones) | CC0 / public domain |
| `spawn.wav` | Generated for Up2048 (synthesised sine tone) | CC0 / public domain |
| `win.wav` | Generated for Up2048 (synthesised arpeggio) | CC0 / public domain |
| `game_over.wav` | Generated for Up2048 (synthesised downward sweep) | CC0 / public domain |

The effects are original, programmatically synthesised tones — no third-party
audio is bundled.

## Images — `assets/images/`

All images are original art created for Up2048 (CC0 / public domain), drawn
programmatically with Pillow using the tile palette in `PLAN.md §13.3` on a
`#2B2D42` ground. No third-party artwork is bundled.

| File | Purpose |
|---|---|
| `icon.png` | 1024×1024 launcher icon: a 2×2 grid of `2 / 4 / 8 / 32` tiles plus the "Up2048" wordmark |
| `icon_foreground.png` | Transparent adaptive-icon foreground (artwork inside the safe zone) |
| `icon_maskable.png` | Navy-backed safe-zone source for PWA maskable icons |
| `splash_logo.png` | Transparent tile-grid logo used for the native and Flutter splash |

The wordmark and tile numerals were rasterised from the macOS system font
(Arial Bold); no font file is shipped. The in-game board and tiles are drawn
with Flutter widgets rather than images.

`assets/store/feature_graphic.png` is the 1024×500 store feature graphic, made
from the same artwork. It is upload-only and is not bundled into the app.

`flutter_launcher_icons` (configured in `pubspec.yaml`) derives the Android
mipmap icons, adaptive icon, iOS `AppIcon.appiconset` and the `web/icons/*`
PWA icons from these sources. `web/favicon.png` is a 64×64 downscale of
`icon.png`.

## Native splash assets

- `android/app/src/main/res/drawable/splash_logo.png` — 240×240 downscale of
  `splash_logo.png`, shown centred by `drawable/launch_background.xml` and
  `drawable-v21/launch_background.xml` over `splash_background`.
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,@2x,@3x}.png` —
  200/400/600 px transparent logos; `LaunchScreen.storyboard` supplies the
  matching navy background.

All are generated from the same original artwork and are CC0.

## Fonts — `assets/fonts/`

Empty. The app uses the platform's bundled system font; no `google_fonts` or
downloaded font is used.

## Icons

Material Icons, bundled by Flutter (`uses-material-design: true`), Apache 2.0.
