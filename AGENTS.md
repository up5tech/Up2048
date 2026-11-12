# Up2048 — Agent Guide

Flutter offline 2048 puzzle game with **4 difficulty levels** (Easy, Medium, Hard, Very Hard). Difficulty is **data-driven** — one immutable `DifficultyConfig` per level, tuned by a headless bot simulator.

**Read `PLAN.md` first** — it is the source of truth. This file is the operating guide for coding agents.

## Hard rules

1. **100% offline.** No `http`, `dio`, Firebase, AdMob, `google_fonts`, or any network package. Fonts, audio, images must live in `assets/` and be declared in `pubspec.yaml`. No `INTERNET` permission in release AndroidManifest. Test in airplane mode.
2. **Domain layer is pure Dart** (`lib/domain/`). It must NOT import `flutter/*`. This keeps unit tests fast and lets `tool/simulate.dart` run with plain `dart run`.
3. **Difficulty is config-driven.** Game logic must never branch on `Difficulty` enum values — all variation comes from `DifficultyConfig` fields (`boardSize`, `spawnTable`, `blockedLayouts`, `doubleSpawnEvery`, `adversaryStrength`, `undoLimit`, `hintLimit`, `removeTileLimit`, `scoreMultiplier`, `targetTile`, `initialTiles`).
4. **Original art only.** Do not copy 2048 clone palettes/assets; use the palette in PLAN.md §13.3.
5. **Assets are royalty-free (CC0).** Record sources in `ASSETS_LICENSE.md`.
6. **Randomness is injectable.** Always pass `Random(seed)` into `Spawner`, `ExpectimaxBot`, `GameController.newGame({seed})` so games/simulations are reproducible.

## Stack

- Flutter stable, Dart 3.x, package name `up_2048`
- `provider` + `ChangeNotifier` for state (`GameController`, `StatsController`, `SettingsController`)
- `shared_preferences` for saves/settings/stats
- `audioplayers` for SFX, `HapticFeedback` built-in
- Widgets rendering (`Stack` + `AnimatedPositioned`); **no game engine**
- `flutter_lints` dev dep; tests with `flutter_test`

## Architecture (PLAN.md §7)

```
UI (screens/widgets) → Controllers (ChangeNotifier) → Domain (pure Dart) → Data/Services
```

Key domain files (`lib/domain/`):

| File | Contents |
|---|---|
| `models/direction.dart` | `enum Direction { up, down, left, right }` |
| `models/board.dart` | `Board` — row-major `List<int>`, `kEmpty=0`, `kBlock=-1` |
| `models/move_result.dart` | `TileMotion`, `MoveResult` (drives animation) |
| `models/difficulty.dart` | `Difficulty`, `DifficultyConfig`, `kDifficulties` map |
| `models/save_data.dart` | `DifficultyStats`, `Settings`, `SavedGame` (JSON) |
| `slide.dart` | `slide()`, `lineIndices()`, `canMove()` — pure, immutable |
| `spawner.dart` | `sampleValue()`, `Spawner` (incl. adversary `_worstCell`), `createInitialBoard()` |
| `evaluate.dart` | `evaluate(Board)` heuristic — used by adversary, bot, hints |
| `expectimax_bot.dart` | `ExpectimaxBot.bestMove()` |

**Golden rule:** `slide()` is a pure function — same board + direction = same result. `TileMotion`s let the UI animate without re-deriving logic. `canMove` must be based on `slide` (blocked cells can isolate empty cells).

## State flow

- `GameController.swipe()`: ignore invalid moves → push `_Snapshot` to undo stack (cap 20) → `slide()` → spawn 1 tile (or 2 on `doubleSpawnEvery`-th move) → build `TileView`s → notify → await ~140 ms anim → `settle()` → win/over check → autosave. Exactly **one buffered swipe** during animation.
- Win: `board.maxTile >= cfg.targetTile` → `GameStatus.won`; player may `keepGoing()`. Game over when `!canMove`.
- Undo restores board/score/moves (spawn from undone move is discarded). Per-difficulty `undoLimit` (0 on Very Hard).
- One saved game **per difficulty** (`game_v1_<name>` key in SharedPreferences); autosave after every move + app pause. Undo stack is NOT saved.
- Keys are versioned (`_v1`) with `try/catch` → corrupted saves fall back to no save.

## UI/rendering notes

- `TileView` gives tiles stable `id` for `AnimatedPositioned`; merges produce **ghosts** sliding to destination + new merged tile (`isMerged`), spawns get `isNew`. `settle()` clears flags after animation.
- Swipe fires at ~24 px pan threshold (don't wait for lift). Buffer one swipe while `_animating`.
- Keyboard (arrows/WASD) for Web/Desktop.
- Long-running work (expectimax hints) in `compute()` isolate, depth ≤ 2.
- `RepaintBoundary` around board; use `Selector`/`context.select` to avoid full-screen rebuilds; target 60 fps.
- Honor `reduceMotion` (all durations → 0).

## Balancing (PLAN.md §21)

- Difficulty numbers in §3.2 are **starting hypotheses**, not final. Before release, run `dart run tool/simulate.dart <games>` and tune per §21.4 — one parameter at a time: `adversaryStrength` → `spawnTable` → `doubleSpawnEvery` → `targetTile` → `blockedLayouts`.
- Target win rates (expectimax depth 2): Easy ≥95%, Medium 60–85%, Hard 20–45%, Very Hard 3–15%. Ordering must hold: Easy > Medium > Hard > Very Hard.
- Record final numbers in `BALANCING.md`. If bots and human playtests disagree, trust humans.

## Workflow / phases (PLAN.md §23)

Implement in order: Phase 0 setup → 1 domain logic+tests → 2 playable Medium → 3 all difficulties → 4 animation → 5 persistence/stats/settings → 6 tools (undo/hint/remove/audio) → 7 balancing → 8 polish/release.

## Commands

```bash
flutter pub get
flutter analyze          # must stay clean (flutter_lints)
flutter test             # unit tests in test/
dart run tool/simulate.dart 200   # headless balancing sim (domain is pure Dart)
flutter run              # dev
flutter build apk --release / appbundle --release
```

## Testing expectations

- `slide` tests are highest priority (merge-once rule, blocked cells, score, `moved` flag) — see PLAN.md §20.1.
- Spawner: seeded RNG reproducibility, weight distribution, adversary picks min-`evaluate` cell at strength 1.
- Config sanity test iterating `kDifficulties` (weights > 0, targetTile power of two, valid/non-corner/non-adjacent stones, `adversaryStrength ∈ [0,1]`).
- Controller tests use `SharedPreferences.setMockInitialValues({})` or fake `StorageService`.
- Before considering work done: `flutter analyze` clean + `flutter test` green.
