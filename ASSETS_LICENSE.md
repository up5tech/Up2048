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

Empty. The app draws its own board and tiles with Flutter widgets, using the
palette defined in `PLAN.md §13.3`.

## Fonts — `assets/fonts/`

Empty. The app uses the platform's bundled system font; no `google_fonts` or
downloaded font is used.

## Icons

Material Icons, bundled by Flutter (`uses-material-design: true`), Apache 2.0.
