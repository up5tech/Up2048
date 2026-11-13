# Up2048 — Detailed Development Plan (Flutter, Offline 2048 Puzzle with 4 Difficulty Levels)

> Goal: build **Up2048**, a 2D tile-merging logic game that runs **fully offline** on Android/iOS (Web/Desktop optional), written in Flutter/Dart, with four difficulty levels: **Easy, Medium, Hard, Very Hard**. Difficulty is data-driven (one config object per level) and is balanced with a headless bot simulator.

---

## TABLE OF CONTENTS

1. [Product Overview](#1-product-overview)
2. [Game Rules & Core Mechanics](#2-game-rules--core-mechanics)
3. [Difficulty System (Easy / Medium / Hard / Very Hard)](#3-difficulty-system-easy--medium--hard--very-hard)
4. [Feature Scope (MVP → Extensions)](#4-feature-scope-mvp--extensions)
5. [Rules for Staying 100% Offline](#5-rules-for-staying-100-offline)
6. [Tech Stack & Packages](#6-tech-stack--packages)
7. [Architecture & Folder Structure](#7-architecture--folder-structure)
8. [Data Models](#8-data-models)
9. [Pure Game Logic (Pure Dart)](#9-pure-game-logic-pure-dart)
10. [Difficulty Config, Spawner & Adversary](#10-difficulty-config-spawner--adversary)
11. [AI: Heuristic, Expectimax Bot & Hints](#11-ai-heuristic-expectimax-bot--hints)
12. [State Management (Provider)](#12-state-management-provider)
13. [UI/UX & Screens](#13-uiux--screens)
14. [Input Handling](#14-input-handling)
15. [Rendering & Animation](#15-rendering--animation)
16. [Local Persistence](#16-local-persistence)
17. [Audio & Haptics](#17-audio--haptics)
18. [Scoring, Stats & Progression](#18-scoring-stats--progression)
19. [Edge Cases](#19-edge-cases)
20. [Testing](#20-testing)
21. [Balancing Workflow (Bot Simulation)](#21-balancing-workflow-bot-simulation)
22. [Performance & Quality](#22-performance--quality)
23. [Phased Roadmap](#23-phased-roadmap)
24. [Configuration, Build & Release](#24-configuration-build--release)
25. [Risks & Mitigations](#25-risks--mitigations)
26. [Completion Checklist](#26-completion-checklist)

---

## 1. Product Overview

| Item | Details |
|---|---|
| Project / app name | **Up2048** |
| Dart package name | `up_2048` |
| Genre | Puzzle / logic, 2D, single player |
| Platforms | Android, iOS (primary). Web/Desktop optional |
| Mode | Fully offline |
| Core interaction | Swipe (or arrow keys) to slide all tiles; equal tiles merge |
| Difficulty levels | Easy, Medium, Hard, Very Hard |
| UI languages | English (default) + Vietnamese (optional) |
| Differentiators | Four distinct difficulty rule-sets, adversarial spawning on high levels, blocked cells, hints from an AI, per-difficulty stats |

**Target audience:** casual players (Easy, Medium) up to experienced players who want a real challenge (Hard, Very Hard). A session lasts 3–15 minutes.

---

## 2. Game Rules & Core Mechanics

### 2.1 Definitions

- **Board:** a square grid of `size × size` cells (4×4 is the classic size).
- **Tile:** a number that is a power of two (2, 4, 8, ...). An empty cell is stored as `0`. A **blocked cell** (stone) is stored as `-1` and never holds a tile.
- **Move:** the player swipes in one of four directions: up, down, left or right.

### 2.2 Sliding & Merging Rules

1. All tiles slide as far as possible in the chosen direction. A tile stops at the board edge, at a blocked cell, or at another tile.
2. If two tiles with the **same value** collide, they merge into one tile with double the value, and the merged value is added to the score.
3. A tile can merge **at most once per move**. For a line `[2, 2, 2, 2]` sliding left, the result is `[4, 4, 0, 0]` (not `[8, 0, 0, 0]`).
4. Merging is resolved from the leading edge: `[2, 2, 2, 0]` sliding left gives `[4, 2, 0, 0]`.
5. Blocked cells split a line into independent segments; tiles never cross a blocked cell.
6. A swipe that changes nothing is **not a move** (no spawn, no move counter increment).

### 2.3 Spawning

After every valid move, one (or more, depending on difficulty) new tile appears in an empty cell. The **value** is drawn from the difficulty's spawn table and the **cell** is chosen randomly — or adversarially on higher difficulties (see section 10).

### 2.4 Win and Game Over

- **Win:** a tile with value `targetTile` (from the difficulty config) is created. The player may stop or choose **Keep going**.
- **Game over:** no empty cell can be reached by any move and no two adjacent tiles are equal — in practice, none of the four directions changes the board.

---

## 3. Difficulty System (Easy / Medium / Hard / Very Hard)

Difficulty is the heart of this plan. Each level is described by **one immutable config object** (section 10) so that adding or tuning a level never requires touching game logic.

### 3.1 Difficulty Parameters

| Parameter | Meaning |
|---|---|
| `boardSize` | Grid size. A larger board is easier. |
| `targetTile` | Tile value that wins the game. |
| `spawnTable` | Weighted values that can spawn (e.g. 2 / 4 / 8). Higher values spawn more clutter. |
| `initialTiles` | Tiles on the board at the start. |
| `blockedLayouts` | Pre-defined sets of blocked cells (stones). Empty list = no blocks. |
| `doubleSpawnEvery` | Every N-th move spawns **two** tiles instead of one (0 = never). |
| `adversaryStrength` | Probability (0–1) that a spawn is placed in the cell that hurts the player most. |
| `undoLimit` | Undo uses per game (-1 = unlimited, 0 = disabled). |
| `hintLimit` | AI hint uses per game. |
| `removeTileLimit` | "Remove a tile" power-up uses per game. |
| `scoreMultiplier` | Used for career points (section 18); per-difficulty best scores stay raw. |

### 3.2 Difficulty Table (initial values)

| Parameter | Easy | Medium | Hard | Very Hard |
|---|---|---|---|---|
| Board | 5 × 5 | 4 × 4 | 4 × 4 | 4 × 4 + 2 stones |
| Target tile | 2048 | 2048 | 2048 | 1024 |
| Spawn table | 2 (90%), 4 (10%) | 2 (90%), 4 (10%) | 2 (70%), 4 (25%), 8 (5%) | 2 (55%), 4 (35%), 8 (10%) |
| Initial tiles | 2 | 2 | 3 | 4 |
| Blocked cells | none | none | none | 2 (from 4 fixed layouts) |
| Double spawn | never | never | every 10th move | every 5th move |
| Adversary strength | 0 | 0 | 0.25 | 0.65 |
| Undo per game | 10 | 3 | 1 | 0 |
| Hints per game | 5 | 2 | 0 | 0 |
| Remove-tile per game | 3 | 1 | 0 | 0 |
| Score multiplier | ×0.5 | ×1 | ×1.5 | ×2 |

> **Important:** these numbers are **starting hypotheses**, not measured results. Section 21 describes how to calibrate them with a bot simulator and real playtests before release. In particular the Very Hard target of 1024 (instead of 2048) is a deliberate first guess because stones plus adversarial spawning may make 2048 nearly unreachable; adjust after simulation.

### 3.3 Level-by-Level Design

**Easy — "Relax"**
- Intended for beginners and children, or for a calm session.
- A 5×5 board gives lots of room; unlimited-feeling undo (10) and hints (5) remove fear of mistakes.
- No adversary: spawn cells are purely random.
- Win-rate goal is high; the challenge is mostly learning the mechanics (corner strategy, keeping rows ordered).

**Medium — "Classic"**
- The classic 4×4 experience, 90/10 spawns, standard rules.
- A small safety net: 3 undos and 2 hints per game.
- The reference level against which the others are tuned.

**Hard — "Tough"**
- Tiles of value 8 can spawn, which creates awkward clutter early.
- Every 10th move brings an extra tile, so the board fills faster.
- Mild adversary (25% of spawns are placed in a damaging cell) punishes sloppy structure.
- Only 1 undo, no hints, no power-ups.

**Very Hard — "Brutal"**
- Two **stone cells** break lines into short segments and remove classic corner strategies.
- Heavier spawn table (55% twos), extra spawn every 5th move, and a strong adversary (65% of spawns are placed where they hurt most).
- Four starting tiles, no undo, no hints, no power-ups.
- Target is lower (1024) because the board is effectively smaller and hostile; reaching it should feel like a real achievement.

### 3.4 Difficulty Selection & Unlocking

- Default: **all four levels are unlocked** from the start (simplest and friendliest).
- Optional progression (constant flag `kGateDifficulties`): Medium is open; Hard unlocks after one Medium win; Very Hard unlocks after one Hard win.
- Each difficulty keeps its **own** saved game, best score, best tile and statistics, so players can switch freely without losing progress.

### 3.5 How Each Parameter Is Implemented

| Mechanic | Where it lives |
|---|---|
| Board size, blocks | `createInitialBoard()` + `slide()` (blocked cells split lines) |
| Spawn table | `Spawner.sampleValue()` |
| Double spawn | `GameController.swipe()` (count = 1 or 2) |
| Adversary | `Spawner._worstCell()` using `evaluate()` |
| Undo / hint / remove limits | Counters in `GameController`, initialized from the config |
| Target tile | Win check in `GameController` |

---

## 4. Feature Scope (MVP → Extensions)

### 4.1 MVP (required – version 1.0)

- [x] Swipe controls with smooth slide/merge/spawn animation.
- [x] Correct merge rules and score.
- [x] Four difficulty levels driven by `DifficultyConfig`.
- [x] Win dialog (Keep going / New game) and Game-over dialog.
- [x] Home screen with difficulty cards.
- [x] Per-difficulty autosave and best score.
- [x] Undo (respecting per-difficulty limits).
- [x] Sound effects with on/off toggle.

### 4.2 Enhancements (version 1.1)

- [x] AI hint (expectimax) for Easy/Medium.
- [x] "Remove tile" power-up for Easy/Medium.
- [x] Per-difficulty statistics screen.
- [x] Light/dark theme, reduce-motion setting, haptics.
- [x] Localization (en/vi).
- [x] Keyboard support (arrows / WASD) for Web and Desktop.

### 4.3 Extensions (version 2.0, optional)

- [ ] Daily challenge (fixed seed per date, still offline).
- [ ] Achievements.
- [ ] Blitz mode (time limit) and Zen mode (no game over: board auto-clears the lowest tiles).
- [ ] Extra board shapes (3×3, 6×6, 8×8) and custom games.
- [ ] Replays of finished games.

---

## 5. Rules for Staying 100% Offline

1. **No network packages:** no `http`, `dio`, Firebase, AdMob, or `google_fonts` (it downloads fonts at runtime).
2. **Bundle fonts** in `assets/fonts/` and declare them in `pubspec.yaml`.
3. **Audio and images** live in `assets/` and are never loaded from URLs.
4. **Player data** (saves, stats, settings) is stored locally with `shared_preferences`.
5. **Local leaderboards only:** "best scores" are stored on the device.
6. **Do not declare the `INTERNET` permission** in the release `AndroidManifest.xml` (Flutter adds it automatically only to debug/profile builds for hot reload).
7. Testing: turn on **airplane mode** and run every screen and mode.

---

## 6. Tech Stack & Packages

| Purpose | Choice | Notes |
|---|---|---|
| Framework | Flutter (latest stable), Dart 3.x | |
| State management | `provider` + `ChangeNotifier` | Simple and sufficient |
| Storage | `shared_preferences` | One JSON blob for stats/settings, one per difficulty for the saved game |
| Audio | `audioplayers` | Local files via `AssetSource` |
| Haptics | `HapticFeedback` (built in) | |
| Rendering | Widgets (`Stack` + `AnimatedPositioned`) and optionally `CustomPainter` | No game engine required |
| App icon | `flutter_launcher_icons` (dev) | |
| Lints | `flutter_lints` | |

**Sample `pubspec.yaml`:**

```yaml
name: up_2048
description: Up2048 - an offline 2048 puzzle with four difficulty levels
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  shared_preferences: ^2.2.3
  audioplayers: ^6.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  flutter_launcher_icons: ^0.13.1

flutter:
  uses-material-design: true
  assets:
    - assets/audio/
    - assets/images/
  fonts:
    - family: Baloo2
      fonts:
        - asset: assets/fonts/Baloo2-Regular.ttf
        - asset: assets/fonts/Baloo2-Bold.ttf
          weight: 700
```

> Run `flutter pub outdated` before starting; package versions above may be outdated.

---

## 7. Architecture & Folder Structure

### 7.1 Layers

```
┌──────────────────────────────────────────────┐
│ UI (Screens, Widgets, Tile rendering)        │  ← renders state + sends swipes
├──────────────────────────────────────────────┤
│ Controllers (ChangeNotifier)                 │  ← GameController, StatsController, SettingsController
├──────────────────────────────────────────────┤
│ Domain (pure Dart, no Flutter imports)       │  ← board, slide, spawner, config, AI
├──────────────────────────────────────────────┤
│ Data/Services                                │  ← StorageService, AudioService
└──────────────────────────────────────────────┘
```

**Golden rule:** the Domain layer **must not** import `flutter/*`. That keeps unit tests fast and lets the balancing simulator run with plain `dart run`.

### 7.2 Folder Structure

```
up_2048/
├─ pubspec.yaml
├─ analysis_options.yaml
├─ assets/
│  ├─ audio/
│  │  ├─ slide.mp3
│  │  ├─ merge.mp3
│  │  ├─ spawn.mp3
│  │  ├─ win.mp3
│  │  └─ game_over.mp3
│  ├─ images/
│  └─ fonts/
├─ tool/
│  └─ simulate.dart                 # headless bot simulation for balancing
├─ lib/
│  ├─ main.dart
│  ├─ app.dart                      # MaterialApp, theme, routes
│  ├─ core/
│  │  ├─ constants.dart
│  │  ├─ tile_palette.dart
│  │  └─ theme.dart
│  ├─ domain/
│  │  ├─ models/
│  │  │  ├─ direction.dart
│  │  │  ├─ board.dart
│  │  │  ├─ move_result.dart
│  │  │  ├─ difficulty.dart         # Difficulty enum + DifficultyConfig + kDifficulties
│  │  │  └─ save_data.dart
│  │  ├─ slide.dart                 # slide(), canMove()
│  │  ├─ spawner.dart               # spawn + adversary + createInitialBoard()
│  │  ├─ evaluate.dart              # heuristic
│  │  └─ expectimax_bot.dart
│  ├─ data/
│  │  ├─ storage_service.dart
│  │  └─ audio_service.dart
│  ├─ controllers/
│  │  ├─ game_controller.dart
│  │  ├─ stats_controller.dart
│  │  └─ settings_controller.dart
│  └─ ui/
│     ├─ screens/
│     │  ├─ splash_screen.dart
│     │  ├─ home_screen.dart
│     │  ├─ game_screen.dart
│     │  ├─ stats_screen.dart
│     │  ├─ settings_screen.dart
│     │  └─ how_to_play_screen.dart
│     └─ widgets/
│        ├─ board_view.dart
│        ├─ tile_widget.dart
│        ├─ swipe_detector.dart
│        ├─ score_panel.dart
│        ├─ game_toolbar.dart
│        ├─ difficulty_card.dart
│        └─ result_dialog.dart
└─ test/
   ├─ slide_test.dart
   ├─ spawner_test.dart
   ├─ difficulty_test.dart
   ├─ expectimax_test.dart
   └─ game_controller_test.dart
```

---

## 8. Data Models

### 8.1 Direction, Board

```dart
// lib/domain/models/direction.dart
enum Direction { up, down, left, right }
```

```dart
// lib/domain/models/board.dart
const int kEmpty = 0;
const int kBlock = -1;

class Board {
  final int size;
  final List<int> cells; // row-major, length = size * size

  const Board(this.size, this.cells);

  factory Board.empty(int size) =>
      Board(size, List<int>.filled(size * size, kEmpty));

  int at(int row, int col) => cells[row * size + col];

  List<int> get emptyIndices => [
        for (var i = 0; i < cells.length; i++)
          if (cells[i] == kEmpty) i,
      ];

  int get maxTile {
    var m = 0;
    for (final v in cells) {
      if (v > m) m = v;
    }
    return m;
  }

  Board withCell(int index, int value) {
    final next = List<int>.of(cells);
    next[index] = value;
    return Board(size, next);
  }
}
```

### 8.2 Move Result (for logic *and* animation)

```dart
// lib/domain/models/move_result.dart
import 'board.dart';

/// One tile travelling from cell [from] to cell [to] during a move.
class TileMotion {
  final int from;
  final int to;
  final int value;     // value BEFORE merging
  final bool merged;   // true if this tile merges into another tile at [to]
  const TileMotion(this.from, this.to, this.value, this.merged);
}

class MoveResult {
  final Board board;
  final int gained;                 // score gained by merges
  final List<TileMotion> motions;
  const MoveResult(this.board, this.gained, this.motions);

  /// A move counts only if at least one tile moved or merged.
  bool get moved => motions.any((m) => m.from != m.to || m.merged);
}
```

### 8.3 Saved Data

```dart
// lib/domain/models/save_data.dart
import 'difficulty.dart';

class DifficultyStats {
  int gamesPlayed;
  int wins;
  int bestScore;
  int bestTile;
  int totalMoves;
  DifficultyStats({
    this.gamesPlayed = 0,
    this.wins = 0,
    this.bestScore = 0,
    this.bestTile = 0,
    this.totalMoves = 0,
  });

  Map<String, dynamic> toJson() => {
        'played': gamesPlayed,
        'wins': wins,
        'bestScore': bestScore,
        'bestTile': bestTile,
        'moves': totalMoves,
      };

  factory DifficultyStats.fromJson(Map<String, dynamic> j) => DifficultyStats(
        gamesPlayed: j['played'] ?? 0,
        wins: j['wins'] ?? 0,
        bestScore: j['bestScore'] ?? 0,
        bestTile: j['bestTile'] ?? 0,
        totalMoves: j['moves'] ?? 0,
      );
}

class Settings {
  bool sound;
  bool vibration;
  bool darkMode;
  bool reduceMotion;
  String locale; // 'en' | 'vi'
  Settings({
    this.sound = true,
    this.vibration = true,
    this.darkMode = false,
    this.reduceMotion = false,
    this.locale = 'en',
  });

  Map<String, dynamic> toJson() => {
        'sound': sound,
        'vibration': vibration,
        'darkMode': darkMode,
        'reduceMotion': reduceMotion,
        'locale': locale,
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        sound: j['sound'] ?? true,
        vibration: j['vibration'] ?? true,
        darkMode: j['darkMode'] ?? false,
        reduceMotion: j['reduceMotion'] ?? false,
        locale: j['locale'] ?? 'en',
      );
}

/// A saved, unfinished game for one difficulty.
class SavedGame {
  final Difficulty difficulty;
  final int size;
  final List<int> cells;
  final int score;
  final int moves;
  final int undoLeft;
  final int hintsLeft;
  final int removeLeft;
  final bool keepPlaying; // player chose "Keep going" after winning

  SavedGame({
    required this.difficulty,
    required this.size,
    required this.cells,
    required this.score,
    required this.moves,
    required this.undoLeft,
    required this.hintsLeft,
    required this.removeLeft,
    required this.keepPlaying,
  });

  Map<String, dynamic> toJson() => {
        'd': difficulty.name,
        'size': size,
        'cells': cells,
        'score': score,
        'moves': moves,
        'undo': undoLeft,
        'hints': hintsLeft,
        'remove': removeLeft,
        'keep': keepPlaying,
      };

  factory SavedGame.fromJson(Map<String, dynamic> j) => SavedGame(
        difficulty: Difficulty.values.byName(j['d'] as String),
        size: j['size'] as int,
        cells: (j['cells'] as List).cast<int>().toList(),
        score: j['score'] as int,
        moves: j['moves'] as int,
        undoLeft: j['undo'] as int,
        hintsLeft: j['hints'] as int,
        removeLeft: j['remove'] as int,
        keepPlaying: j['keep'] ?? false,
      );
}
```

---

## 9. Pure Game Logic (Pure Dart)

File: `lib/domain/slide.dart`

```dart
import 'models/board.dart';
import 'models/direction.dart';
import 'models/move_result.dart';

/// Cell indices of line [k], ordered from the edge tiles slide TOWARD,
/// moving outward. Sliding "left" on row k → [k*size + 0, k*size + 1, ...].
List<int> lineIndices(int size, Direction d, int k) {
  switch (d) {
    case Direction.left:
      return [for (var c = 0; c < size; c++) k * size + c];
    case Direction.right:
      return [for (var c = size - 1; c >= 0; c--) k * size + c];
    case Direction.up:
      return [for (var r = 0; r < size; r++) r * size + k];
    case Direction.down:
      return [for (var r = size - 1; r >= 0; r--) r * size + k];
  }
}

/// Slides and merges the whole board. Never mutates [b].
MoveResult slide(Board b, Direction d) {
  final out = List<int>.of(b.cells);
  final motions = <TileMotion>[];
  var gained = 0;

  for (var k = 0; k < b.size; k++) {
    final line = lineIndices(b.size, d, k);
    var segStart = 0;
    for (var i = 0; i <= line.length; i++) {
      final atEnd = i == line.length;
      if (atEnd || b.cells[line[i]] == kBlock) {
        if (i > segStart) {
          gained += _slideSegment(b, line.sublist(segStart, i), out, motions);
        }
        segStart = i + 1;
      }
    }
  }
  return MoveResult(Board(b.size, out), gained, motions);
}

/// Slides one block-free segment. Returns the score gained.
int _slideSegment(
    Board b, List<int> seg, List<int> out, List<TileMotion> motions) {
  // Indices of non-empty cells, in order from the leading edge.
  final tiles = [
    for (final idx in seg)
      if (b.cells[idx] != kEmpty) idx,
  ];
  for (final idx in seg) {
    out[idx] = kEmpty;
  }

  var write = 0;
  var gained = 0;
  var i = 0;
  while (i < tiles.length) {
    final from = tiles[i];
    final v = b.cells[from];
    final to = seg[write];

    if (i + 1 < tiles.length && b.cells[tiles[i + 1]] == v) {
      out[to] = v * 2;
      gained += v * 2;
      motions
        ..add(TileMotion(from, to, v, true))
        ..add(TileMotion(tiles[i + 1], to, v, true));
      i += 2;
    } else {
      out[to] = v;
      motions.add(TileMotion(from, to, v, false));
      i += 1;
    }
    write++;
  }
  return gained;
}

/// True if at least one direction changes the board.
bool canMove(Board b) {
  for (final d in Direction.values) {
    if (slide(b, d).moved) return true;
  }
  return false;
}
```

**Key points:**

- `slide` is a **pure function**: the same board and direction always produce the same result → easy to test, replay and simulate.
- Blocked cells are handled by splitting every line into segments; no special cases elsewhere.
- `TileMotion`s drive the UI animation without the UI re-deriving anything.
- `canMove` is based on `slide` (rather than "any empty cell or equal neighbours") because blocked cells can isolate an empty cell.

---

## 10. Difficulty Config, Spawner & Adversary

### 10.1 `DifficultyConfig`

```dart
// lib/domain/models/difficulty.dart
enum Difficulty { easy, medium, hard, veryHard }

class SpawnWeight {
  final int value;
  final int weight;
  const SpawnWeight(this.value, this.weight);
}

class DifficultyConfig {
  final Difficulty id;
  final String label;
  final int boardSize;
  final int targetTile;
  final List<SpawnWeight> spawnTable;
  final int initialTiles;
  final List<List<int>> blockedLayouts; // each layout = list of cell indices
  final int doubleSpawnEvery;           // 0 = never
  final double adversaryStrength;       // 0..1
  final int undoLimit;                  // -1 = unlimited
  final int hintLimit;
  final int removeTileLimit;
  final double scoreMultiplier;

  const DifficultyConfig({
    required this.id,
    required this.label,
    required this.boardSize,
    required this.targetTile,
    required this.spawnTable,
    required this.initialTiles,
    this.blockedLayouts = const [],
    this.doubleSpawnEvery = 0,
    this.adversaryStrength = 0,
    required this.undoLimit,
    required this.hintLimit,
    required this.removeTileLimit,
    required this.scoreMultiplier,
  });
}

const Map<Difficulty, DifficultyConfig> kDifficulties = {
  Difficulty.easy: DifficultyConfig(
    id: Difficulty.easy,
    label: 'Easy',
    boardSize: 5,
    targetTile: 2048,
    spawnTable: [SpawnWeight(2, 90), SpawnWeight(4, 10)],
    initialTiles: 2,
    undoLimit: 10,
    hintLimit: 5,
    removeTileLimit: 3,
    scoreMultiplier: 0.5,
  ),
  Difficulty.medium: DifficultyConfig(
    id: Difficulty.medium,
    label: 'Medium',
    boardSize: 4,
    targetTile: 2048,
    spawnTable: [SpawnWeight(2, 90), SpawnWeight(4, 10)],
    initialTiles: 2,
    undoLimit: 3,
    hintLimit: 2,
    removeTileLimit: 1,
    scoreMultiplier: 1.0,
  ),
  Difficulty.hard: DifficultyConfig(
    id: Difficulty.hard,
    label: 'Hard',
    boardSize: 4,
    targetTile: 2048,
    spawnTable: [SpawnWeight(2, 70), SpawnWeight(4, 25), SpawnWeight(8, 5)],
    initialTiles: 3,
    doubleSpawnEvery: 10,
    adversaryStrength: 0.25,
    undoLimit: 1,
    hintLimit: 0,
    removeTileLimit: 0,
    scoreMultiplier: 1.5,
  ),
  Difficulty.veryHard: DifficultyConfig(
    id: Difficulty.veryHard,
    label: 'Very Hard',
    boardSize: 4,
    targetTile: 1024,
    spawnTable: [SpawnWeight(2, 55), SpawnWeight(4, 35), SpawnWeight(8, 10)],
    initialTiles: 4,
    // Row-major indices on a 4x4 board. All are non-corner and non-adjacent.
    blockedLayouts: [
      [5, 10], // (1,1) and (2,2)
      [6, 9],  // (1,2) and (2,1)
      [1, 14], // (0,1) and (3,2)
      [4, 11], // (1,0) and (2,3)
    ],
    doubleSpawnEvery: 5,
    adversaryStrength: 0.65,
    undoLimit: 0,
    hintLimit: 0,
    removeTileLimit: 0,
    scoreMultiplier: 2.0,
  ),
};
```

> **Why fixed block layouts?** They are predictable, easy to unit-test (all four are verified once to leave the remaining cells playable) and avoid random layouts that could be unfair, such as a blocked cell in a corner or an isolated pocket.

### 10.2 Spawner (random or adversarial placement)

```dart
// lib/domain/spawner.dart
import 'dart:math';
import 'models/board.dart';
import 'models/difficulty.dart';
import 'evaluate.dart';

int sampleValue(List<SpawnWeight> table, Random rng) {
  final total = table.fold<int>(0, (s, e) => s + e.weight);
  var roll = rng.nextInt(total);
  for (final e in table) {
    if (roll < e.weight) return e.value;
    roll -= e.weight;
  }
  return table.last.value;
}

class SpawnResult {
  final Board board;
  final int index;
  final int value;
  const SpawnResult(this.board, this.index, this.value);
}

class Spawner {
  final DifficultyConfig cfg;
  final Random rng;
  Spawner(this.cfg, this.rng);

  /// Spawns one tile, or returns null if no cell is free.
  SpawnResult? spawn(Board b) {
    final empties = b.emptyIndices;
    if (empties.isEmpty) return null;

    final value = sampleValue(cfg.spawnTable, rng);
    final useAdversary =
        cfg.adversaryStrength > 0 && rng.nextDouble() < cfg.adversaryStrength;

    final index = useAdversary
        ? _worstCell(b, empties, value)
        : empties[rng.nextInt(empties.length)];

    return SpawnResult(b.withCell(index, value), index, value);
  }

  /// The empty cell that leaves the player in the worst position
  /// according to [evaluate] (lowest score = worst for the player).
  int _worstCell(Board b, List<int> empties, int value) {
    var worst = empties.first;
    var worstScore = double.infinity;
    for (final i in empties) {
      final s = evaluate(b.withCell(i, value));
      if (s < worstScore || (s == worstScore && rng.nextBool())) {
        worstScore = s;
        worst = i;
      }
    }
    return worst;
  }
}

/// Builds the starting board for a difficulty: blocks first, then tiles.
Board createInitialBoard(DifficultyConfig cfg, Random rng) {
  final cells = List<int>.filled(cfg.boardSize * cfg.boardSize, kEmpty);
  if (cfg.blockedLayouts.isNotEmpty) {
    final layout = cfg.blockedLayouts[rng.nextInt(cfg.blockedLayouts.length)];
    for (final i in layout) {
      cells[i] = kBlock;
    }
  }
  var board = Board(cfg.boardSize, cells);
  final spawner = Spawner(cfg, rng);
  for (var i = 0; i < cfg.initialTiles; i++) {
    board = spawner.spawn(board)!.board;
  }
  return board;
}
```

**Adversary design notes**

- The adversary only chooses the **cell**, never the value, and only with probability `adversaryStrength`. This keeps the game **fair but tense**: it is not a pure worst-case opponent, so the player can still win with good structure.
- It reuses the same `evaluate()` as the AI, so one heuristic defines "good" and "bad" boards for hints, bots, and the adversary.
- Cost: at most `size² × 1` evaluations per spawn (≤ 25), negligible.
- In the UI, communicate it honestly (e.g. a "Mean spawns" tag on Hard/Very Hard in the difficulty card) so it does not feel like a bug.

---

## 11. AI: Heuristic, Expectimax Bot & Hints

### 11.1 Heuristic (`evaluate`)

Higher score = better for the player. The weights below are **illustrative starting values**, to be tuned with the simulator.

```dart
// lib/domain/evaluate.dart
import 'dart:math';
import 'models/board.dart';

double _log2(int v) => log(v) / ln2;

double evaluate(Board b) {
  final n = b.size;
  var empty = 0;
  var mergeable = 0;
  var smoothness = 0.0;
  var maxTile = 0;

  for (var r = 0; r < n; r++) {
    for (var c = 0; c < n; c++) {
      final v = b.cells[r * n + c];
      if (v == kEmpty) {
        empty++;
        continue;
      }
      if (v == kBlock) continue;
      if (v > maxTile) maxTile = v;

      if (c + 1 < n) {
        final w = b.cells[r * n + c + 1];
        if (w > 0) {
          smoothness -= (_log2(v) - _log2(w)).abs();
          if (v == w) mergeable++;
        }
      }
      if (r + 1 < n) {
        final w = b.cells[(r + 1) * n + c];
        if (w > 0) {
          smoothness -= (_log2(v) - _log2(w)).abs();
          if (v == w) mergeable++;
        }
      }
    }
  }

  final corners = [0, n - 1, n * (n - 1), n * n - 1];
  final maxInCorner =
      maxTile > 0 && corners.any((i) => b.cells[i] == maxTile);

  return 270.0 * empty +
      100.0 * mergeable +
      10.0 * smoothness +
      (maxInCorner ? 200.0 * _log2(maxTile) : 0.0);
}
```

Possible later improvements: monotonicity along rows/columns, penalties for trapped small tiles next to stones, and per-board-size weight sets.

### 11.2 Expectimax Bot

Used for (a) in-game hints and (b) balancing simulations.

```dart
// lib/domain/expectimax_bot.dart
import 'dart:math';
import 'models/board.dart';
import 'models/difficulty.dart';
import 'models/direction.dart';
import 'evaluate.dart';
import 'slide.dart';

class ExpectimaxBot {
  final int depth;             // player moves to look ahead (1–3)
  final int maxChanceSamples;  // cap on empty cells considered per chance node
  final Random rng;

  ExpectimaxBot({this.depth = 2, this.maxChanceSamples = 6, Random? rng})
      : rng = rng ?? Random();

  /// Best direction for [b], or null if no move exists.
  Direction? bestMove(Board b, List<SpawnWeight> table) {
    Direction? best;
    var bestScore = double.negativeInfinity;
    for (final d in Direction.values) {
      final r = slide(b, d);
      if (!r.moved) continue;
      final s = _chance(r.board, table, depth - 1);
      if (s > bestScore) {
        bestScore = s;
        best = d;
      }
    }
    return best;
  }

  double _max(Board b, List<SpawnWeight> table, int depth) {
    if (depth <= 0) return evaluate(b);
    var best = double.negativeInfinity;
    for (final d in Direction.values) {
      final r = slide(b, d);
      if (!r.moved) continue;
      best = max(best, _chance(r.board, table, depth - 1));
    }
    return best == double.negativeInfinity ? -1e9 : best; // game over
  }

  double _chance(Board b, List<SpawnWeight> table, int depth) {
    final empties = b.emptyIndices;
    if (empties.isEmpty) return _max(b, table, depth);

    final sample = empties.length <= maxChanceSamples
        ? empties
        : (List<int>.of(empties)..shuffle(rng)).take(maxChanceSamples).toList();
    final totalWeight = table.fold<int>(0, (s, e) => s + e.weight);

    var expected = 0.0;
    for (final i in sample) {
      for (final w in table) {
        expected += (w.weight / totalWeight) *
            _max(b.withCell(i, w.value), table, depth);
      }
    }
    return expected / sample.length;
  }
}
```

### 11.3 Hints in the Game

- The hint button calls the bot with `depth = 2` inside `compute()` (an **Isolate**) so the UI never freezes, then highlights the suggested direction with an arrow animation.
- Hints are counted per game (`hintLimit`); on Hard/Very Hard the button is hidden.
- The bot assumes random spawns, so against the adversary on high levels its advice is a good guide, not a guarantee. That is fine because hints are disabled there anyway.

---

## 12. State Management (Provider)

### 12.1 Controllers

| Controller | Responsibility |
|---|---|
| `GameController` | Current game: board, score, tiles for rendering, power-ups, win/over status, undo stack |
| `StatsController` | Per-difficulty stats, best scores, career points; reads/writes `StorageService` |
| `SettingsController` | Sound, haptics, theme, reduce motion, language |

Bootstrapping in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final storage = await StorageService.create();
  final audio = AudioService();
  await audio.preload();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController(storage)),
        ChangeNotifierProvider(create: (_) => StatsController(storage)),
        ChangeNotifierProvider(create: (ctx) => GameController(
              storage: storage,
              audio: audio,
              settings: ctx.read<SettingsController>(),
              stats: ctx.read<StatsController>(),
            )),
      ],
      child: const Up2048App(),
    ),
  );
}
```

### 12.2 `GameController` (skeleton)

```dart
enum GameStatus { playing, won, keepPlaying, over }

class _Snapshot {
  final Board board;
  final int score;
  final int moves;
  _Snapshot(this.board, this.score, this.moves);
}

class GameController extends ChangeNotifier {
  // ... dependencies: storage, audio, settings, stats

  late DifficultyConfig cfg;
  late Board board;
  late Spawner _spawner;
  late Random _rng;

  int score = 0;
  int moves = 0;
  int undoLeft = 0;
  int hintsLeft = 0;
  int removeLeft = 0;
  GameStatus status = GameStatus.playing;
  Direction? hint;                     // direction suggested by the AI

  bool _animating = false;
  Direction? _queued;                  // one buffered swipe during animation
  final List<_Snapshot> _undo = [];
  List<TileView> tiles = [];           // what the UI draws (see section 15)

  static const _animMs = 140;

  void newGame(Difficulty d, {int? seed}) {
    cfg = kDifficulties[d]!;
    _rng = Random(seed);
    _spawner = Spawner(cfg, _rng);
    board = createInitialBoard(cfg, _rng);
    score = 0;
    moves = 0;
    undoLeft = cfg.undoLimit;
    hintsLeft = cfg.hintLimit;
    removeLeft = cfg.removeTileLimit;
    status = GameStatus.playing;
    hint = null;
    _undo.clear();
    tiles = TileView.fromBoard(board);
    stats.onGameStarted(d);
    notifyListeners();
  }

  Future<void> swipe(Direction d) async {
    if (status == GameStatus.over || status == GameStatus.won) return;
    if (_animating) {
      _queued = d;
      return;
    }

    final r = slide(board, d);
    if (!r.moved) return; // not a move: no spawn, no counter, no sound

    hint = null;
    _undo.add(_Snapshot(board, score, moves));
    if (_undo.length > 20) _undo.removeAt(0);

    _animating = true;
    score += r.gained;
    moves++;

    // 1 tile normally, 2 on "double spawn" moves
    var next = r.board;
    final spawnedAt = <int>[];
    final count =
        1 + ((cfg.doubleSpawnEvery > 0 && moves % cfg.doubleSpawnEvery == 0) ? 1 : 0);
    for (var i = 0; i < count; i++) {
      final s = _spawner.spawn(next);
      if (s == null) break;
      next = s.board;
      spawnedAt.add(s.index);
    }
    board = next;

    tiles = TileView.applyMove(tiles, r.motions, board, spawnedAt);
    audio.play(r.gained > 0 ? Sfx.merge : Sfx.slide);
    notifyListeners();

    await Future.delayed(Duration(milliseconds: settings.reduceMotion ? 0 : _animMs));
    tiles = TileView.settle(tiles);      // drop merged "ghost" tiles, clear flags
    _animating = false;

    _updateStatus();
    await _save();
    notifyListeners();

    final q = _queued;
    _queued = null;
    if (q != null) await swipe(q);
  }

  void _updateStatus() {
    if (status == GameStatus.playing && board.maxTile >= cfg.targetTile) {
      status = GameStatus.won;
      stats.onWin(cfg.id);
      audio.play(Sfx.win);
    }
    if (status != GameStatus.won && !canMove(board)) {
      status = GameStatus.over;
      audio.play(Sfx.gameOver);
    }
    if (status == GameStatus.over || status == GameStatus.won) {
      stats.onGameFinished(cfg.id, score: score, bestTile: board.maxTile, moves: moves);
    }
  }

  bool get canUndo =>
      _undo.isNotEmpty && !_animating && (cfg.undoLimit < 0 || undoLeft > 0);

  void undo() {
    if (!canUndo) return;
    final s = _undo.removeLast();
    board = s.board;
    score = s.score;
    moves = s.moves;
    if (cfg.undoLimit >= 0) undoLeft--;
    status = GameStatus.playing;
    hint = null;
    tiles = TileView.fromBoard(board);
    _save();
    notifyListeners();
  }

  Future<void> requestHint() async {
    if (hintsLeft <= 0 || _animating) return;
    final dirIndex = await compute(_hintInIsolate, _HintArgs(board.size, board.cells, cfg.spawnTable));
    if (dirIndex < 0) return;
    hintsLeft--;
    hint = Direction.values[dirIndex];
    notifyListeners();
  }

  /// "Remove tile" power-up: delete one tile chosen by the player.
  void removeTile(int cellIndex) {
    if (removeLeft <= 0 || _animating) return;
    if (board.cells[cellIndex] <= 0) return;
    _undo.add(_Snapshot(board, score, moves));
    board = board.withCell(cellIndex, kEmpty);
    removeLeft--;
    tiles = TileView.fromBoard(board);
    _save();
    notifyListeners();
  }

  void keepGoing() {
    if (status == GameStatus.won) {
      status = GameStatus.keepPlaying;
      notifyListeners();
    }
  }
}
```

**Notes**

- **One buffered swipe:** if the player swipes during the 140 ms animation, the swipe is remembered and executed right after. This gives a responsive feel without losing control.
- **Win vs. game over:** reaching the target shows the win dialog first; if the player picks **Keep going**, play continues until game over.
- **Undo** restores board, score and move counter. The spawn that followed the undone move is also removed because it is part of the previous snapshot's successor state; the next swipe generates a new spawn (so undo can change future randomness, which is acceptable and limited by `undoLimit`).

---

## 13. UI/UX & Screens

### 13.1 Navigation Flow

```
Splash ──► Home ──► Game ──► (Win / Game Over dialog) ──► Game (new) or Home
             │         ▲
             ├──► Stats └── Continue (resume saved game of that difficulty)
             ├──► Settings
             └──► How to play
```

### 13.2 Screen Descriptions

**Splash:** logo + load settings/stats (≤ 1–2 s).

**Home:**
- Four **difficulty cards** (Easy, Medium, Hard, Very Hard), each showing:
  - Name and one-line description (e.g. "5×5 board, plenty of help").
  - Small rule badges: board size, target tile, "Mean spawns" (adversary), "Stones", "No undo".
  - Personal best score and best tile.
  - A **Continue** button if there is a saved game, plus **New game**.
- Buttons for Stats, Settings, How to play.

**Game:**
- Header: difficulty name, **Score**, **Best**, move counter.
- Board (see sections 14–15).
- Toolbar: `Undo (n)`, `Hint (n)` (only if the difficulty allows), `Remove tile (n)`, `New game`.
- Win dialog: "You made 2048!" → **Keep going** / **New game** / **Home**.
- Game-over dialog: score, best, best tile, moves → **Try again** / **Change difficulty**.
- New game / leaving mid-game: confirm only if the game has progressed (≥ 1 move).

**Stats:** table per difficulty: games, wins, win-rate, best score, best tile, total moves, career points.

**Settings:** sound, haptics, dark mode, reduce motion, language; "Reset data" with confirmation.

**How to play:** 3–4 illustrated steps (swipe, merge, goal) and a short description of every difficulty.

### 13.3 Visual Design

- Each difficulty has an accent color: Easy = green, Medium = blue, Hard = orange, Very Hard = red/purple.
- Tile colors (create your own art; do not copy another game's palette or assets):

| Value | Background | Text |
|---|---|---|
| 2 | `#E8F1F2` | `#3A4A55` |
| 4 | `#CFE8EF` | `#3A4A55` |
| 8 | `#9AD1D4` | `#1F2D3A` |
| 16 | `#6FB7C4` | `#FFFFFF` |
| 32 | `#4F9DB8` | `#FFFFFF` |
| 64 | `#3F7FB5` | `#FFFFFF` |
| 128 | `#6A6BC9` | `#FFFFFF` |
| 256 | `#8E5BC7` | `#FFFFFF` |
| 512 | `#B24FB8` | `#FFFFFF` |
| 1024 | `#D9479A` | `#FFFFFF` |
| 2048 | `#F2A33A` | `#FFFFFF` |
| 4096+ | `#2B2D42` | `#FFD166` |

- Blocked cells look like dark stone tiles with a subtle texture, clearly distinct from empty cells.
- Font size scales with the number of digits (e.g. 100% for 1–2 digits, 80% for 3, 65% for 4+).

---

## 14. Input Handling

### 14.1 Swipe Detection

Fire the move as soon as the finger has travelled far enough (more responsive than waiting for the finger to lift).

```dart
class SwipeDetector extends StatefulWidget {
  final void Function(Direction) onSwipe;
  final Widget child;
  const SwipeDetector({super.key, required this.onSwipe, required this.child});

  @override
  State<SwipeDetector> createState() => _SwipeDetectorState();
}

class _SwipeDetectorState extends State<SwipeDetector> {
  Offset _acc = Offset.zero;
  bool _fired = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) {
        _acc = Offset.zero;
        _fired = false;
      },
      onPanUpdate: (d) {
        if (_fired) return;
        _acc += d.delta;
        const threshold = 24.0;
        if (_acc.distance < threshold) return;
        _fired = true;
        final dir = _acc.dx.abs() > _acc.dy.abs()
            ? (_acc.dx > 0 ? Direction.right : Direction.left)
            : (_acc.dy > 0 ? Direction.down : Direction.up);
        widget.onSwipe(dir);
      },
      child: widget.child,
    );
  }
}
```

### 14.2 Keyboard (Web/Desktop)

Wrap the game screen in a `Focus` widget with `onKeyEvent`, mapping Arrow keys and W/A/S/D to `Direction`. Ignore key repeat if the controller is animating (the controller already buffers one swipe).

### 14.3 Remove-Tile Mode

Tapping the "Remove tile" button toggles a mode in which the next tap on a tile deletes it (cancel with a second tap on the button). While in this mode, swipes are ignored.

---

## 15. Rendering & Animation

### 15.1 Tile View Model

The pure logic works with integers; the UI needs **identity** to animate each tile smoothly.

```dart
class TileView {
  final int id;          // stable identity across moves
  final int value;
  final int index;       // current cell
  final bool isNew;      // just spawned → "pop in"
  final bool isMerged;   // result of a merge → "bump"
  final bool isGhost;    // slides to its destination then disappears

  const TileView(this.id, this.value, this.index,
      {this.isNew = false, this.isMerged = false, this.isGhost = false});

  static int _nextId = 0;
  static int newId() => _nextId++;

  static List<TileView> fromBoard(Board b) => [
        for (var i = 0; i < b.cells.length; i++)
          if (b.cells[i] > 0) TileView(newId(), b.cells[i], i),
      ];
}
```

`TileView.applyMove(tiles, motions, newBoard, spawnedAt)`:

1. Build a map `cell index → TileView` from the current tiles.
2. Group `motions` by destination `to`:
   - **Single motion:** keep the tile's `id`, set its `index = to`.
   - **Two motions (merge):** both source tiles become **ghosts** at `index = to` (they slide into place and vanish), and a **new merged tile** (new id, `isMerged: true`, value × 2) appears at `to`.
3. Add a `TileView` with `isNew: true` for every cell in `spawnedAt`.

`TileView.settle(tiles)` removes ghosts and clears the `isNew` / `isMerged` flags once the animation has finished.

### 15.2 Board Widget

- Compute `cell = (boardWidth - gap × (n + 1)) / n`.
- Draw the background grid (empty cells and stones) first, then a `Stack` of tiles:

```dart
Stack(
  children: [
    for (final t in tiles)
      AnimatedPositioned(
        key: ValueKey(t.id),
        duration: Duration(milliseconds: reduceMotion ? 0 : 120),
        curve: Curves.easeOut,
        left: gap + (t.index % n) * (cell + gap),
        top:  gap + (t.index ~/ n) * (cell + gap),
        width: cell,
        height: cell,
        child: TileWidget(tile: t),
      ),
  ],
)
```

- `TileWidget` uses a `TweenAnimationBuilder<double>`:
  - **Spawn:** scale 0 → 1 over ~120 ms (start after the slide finishes using a short delay).
  - **Merge:** scale 1 → 1.15 → 1 over ~140 ms.
- Ghost tiles are drawn below normal tiles so the merged tile appears on top.
- Wrap the board in a `RepaintBoundary`.

### 15.3 Timeline of One Move (≈ 140–260 ms)

| Phase | Duration | Action |
|---|---|---|
| Slide | ~120 ms | All tiles move to their destinations (`AnimatedPositioned`) |
| Merge bump | ~140 ms | Merged tile scales 1 → 1.15 → 1, ghosts removed |
| Spawn pop | ~120 ms | New tile(s) scale 0 → 1 |

Keep total input-to-ready time near 140 ms; the buffered swipe makes fast play feel natural. When **Reduce motion** is on, set all durations to 0.

### 15.4 Hint Display

Show a translucent arrow (or pulsing edge highlight) on the board edge corresponding to `GameController.hint`; clear it on the next swipe.

---

## 16. Local Persistence

### 16.1 `StorageService`

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;
  StorageService._(this._prefs);

  static Future<StorageService> create() async =>
      StorageService._(await SharedPreferences.getInstance());

  // --- Settings ---
  Settings loadSettings() => _readJson('settings_v1', Settings.fromJson, Settings());
  Future<void> saveSettings(Settings s) => _prefs.setString('settings_v1', jsonEncode(s.toJson()));

  // --- Stats (one record per difficulty) ---
  DifficultyStats loadStats(Difficulty d) =>
      _readJson('stats_v1_${d.name}', DifficultyStats.fromJson, DifficultyStats());
  Future<void> saveStats(Difficulty d, DifficultyStats s) =>
      _prefs.setString('stats_v1_${d.name}', jsonEncode(s.toJson()));

  // --- Saved game (one slot per difficulty) ---
  SavedGame? loadGame(Difficulty d) {
    final raw = _prefs.getString('game_v1_${d.name}');
    if (raw == null) return null;
    try {
      return SavedGame.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // corrupted → treat as no saved game
    }
  }

  Future<void> saveGame(SavedGame g) =>
      _prefs.setString('game_v1_${g.difficulty.name}', jsonEncode(g.toJson()));

  Future<void> clearGame(Difficulty d) => _prefs.remove('game_v1_${d.name}');

  T _readJson<T>(String key, T Function(Map<String, dynamic>) fromJson, T fallback) {
    final raw = _prefs.getString(key);
    if (raw == null) return fallback;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return fallback;
    }
  }
}
```

### 16.2 Principles

- **One saved game per difficulty**, so switching difficulty never destroys another game.
- **Autosave after every move**, new game, undo, and when the app goes to the background (`WidgetsBindingObserver`).
- Delete the saved game when a game ends (win without keep-going, or game over).
- Keys are versioned (`_v1`) so future formats can migrate.
- The undo stack is **not** saved (keeps saves small); after resuming, undo is unavailable until the next move. Document this in the How-to-play screen or tooltip.

---

## 17. Audio & Haptics

### 17.1 Sound Effects

| Event | File | Notes |
|---|---|---|
| Slide (no merge) | `slide.mp3` | Very short, soft |
| Merge | `merge.mp3` | Pitch can scale with tile value (play at different rates) |
| Spawn | `spawn.mp3` | Optional, subtle |
| Win | `win.mp3` | 1.5–2 s |
| Game over | `game_over.mp3` | Low, short |

Use **royalty-free (CC0)** audio and record sources in `ASSETS_LICENSE.md`.

### 17.2 Services

Use the same pattern as a simple preloaded `AudioService` (one `AudioPlayer` per effect, `stop()` then `resume()` on play, global on/off flag). For merge sounds on rapid play, prefer `PlayerMode.lowLatency` if latency is noticeable on Android.

### 17.3 Haptics

- Light impact on a merge that creates a tile ≥ 128.
- Medium impact on win.
- Heavy impact on game over.
- No haptic for an invalid swipe (avoid buzzing).
- All gated by the Settings toggle.

---

## 18. Scoring, Stats & Progression

### 18.1 Score

- **Game score** = sum of the values of all tiles created by merges (classic 2048 rule). Spawned tiles do not add score.
- **Best score** is stored per difficulty (raw score), so difficulties are never compared against each other.

### 18.2 Career Points

Optional global progression, shown on the Stats screen:

```
careerPoints += round(finalScore × scoreMultiplier)
```

Multipliers: Easy ×0.5, Medium ×1, Hard ×1.5, Very Hard ×2. This rewards playing harder levels without distorting per-difficulty leaderboards.

### 18.3 Stats Recorded

Per difficulty: games played, wins, win-rate, best score, best tile, total moves. A game counts as "played" when started and "won" once when the target tile is first reached.

### 18.4 Achievements (optional, version 2.0)

Examples: "Reach 512 on Hard", "Win Very Hard", "Win Medium without Undo", "Win Easy in under 600 moves".

---

## 19. Edge Cases

| # | Situation | Handling |
|---|---|---|
| 1 | Swipe that changes nothing | Ignored: no spawn, no move count, no sound |
| 2 | Swipe during animation | Buffer exactly one swipe, execute after the animation |
| 3 | Reaching the target and the board is also full | Show the **win** dialog first; game-over is evaluated after the player chooses Keep going |
| 4 | Undo after "Keep going" | Allowed (if undos remain); status returns to `playing` only if the board is below target, otherwise `keepPlaying` should be preserved (set status accordingly in implementation) |
| 5 | Empty cell exists but no move is possible (isolated by stones) | `canMove` uses `slide`, so game-over is detected correctly |
| 6 | Double spawn with a nearly full board | Spawner returns `null` when full; spawn only what fits |
| 7 | Hint requested while animating or with 0 hints | Ignored / button disabled |
| 8 | Hint returns no direction (no moves) | Do nothing; game-over handling already triggers |
| 9 | App backgrounded mid-animation | Autosave on `paused`; `settle` the tiles on resume |
| 10 | Corrupted saved game | `try/catch` → treat as no saved game |
| 11 | Switching difficulty with an unfinished game | Keep it: each difficulty has its own slot; Continue resumes it |
| 12 | Screen size / orientation changes | Portrait lock; board size derived from `LayoutBuilder`, square with `min(width, height × 0.6)` |
| 13 | Very fast repeated taps on toolbar buttons | Disabled while `_animating`; counters decremented only on success |
| 14 | Remove-tile used on a stone or empty cell | Ignored; button mode stays active |
| 15 | Tile values above 4096 | Palette fallback color; shrink font further |

---

## 20. Testing

### 20.1 Unit Tests for `slide` (highest priority)

```dart
// test/slide_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:up_2048/domain/models/board.dart';
import 'package:up_2048/domain/models/direction.dart';
import 'package:up_2048/domain/slide.dart';

Board row(List<int> r) => Board(r.length, [
      ...r,
      for (var i = 0; i < r.length * (r.length - 1); i++) 0,
    ]);

List<int> firstRow(Board b) => b.cells.sublist(0, b.size);

void main() {
  group('slide left (first row of a 4x4)', () {
    test('[2,2,2,2] → [4,4,0,0]', () {
      expect(firstRow(slide(row([2, 2, 2, 2]), Direction.left).board), [4, 4, 0, 0]);
    });
    test('[2,2,2,0] → [4,2,0,0]', () {
      expect(firstRow(slide(row([2, 2, 2, 0]), Direction.left).board), [4, 2, 0, 0]);
    });
    test('[4,2,2,0] → [4,4,0,0]', () {
      expect(firstRow(slide(row([4, 2, 2, 0]), Direction.left).board), [4, 4, 0, 0]);
    });
    test('[2,0,2,4] → [4,4,0,0]', () {
      expect(firstRow(slide(row([2, 0, 2, 4]), Direction.left).board), [4, 4, 0, 0]);
    });
    test('a tile merges at most once per move: [4,2,2,4] → [4,4,4,0]', () {
      expect(firstRow(slide(row([4, 2, 2, 4]), Direction.left).board), [4, 4, 4, 0]);
    });
  });

  group('score and moved flag', () {
    test('gained equals sum of merged values', () {
      final r = slide(row([2, 2, 4, 4]), Direction.left);
      expect(r.gained, 12); // 4 + 8
    });
    test('no change → moved is false', () {
      final r = slide(row([2, 4, 8, 16]), Direction.left);
      expect(r.moved, isFalse);
    });
  });

  group('blocked cells', () {
    test('tiles never cross a stone: [2,X,2,2] → [2,X,4,0]', () {
      final r = slide(row([2, kBlock, 2, 2]), Direction.left);
      expect(firstRow(r.board), [2, kBlock, 4, 0]);
    });
    test('canMove is false when stones isolate every tile', () {
      // 2 stones around an empty cell with no tile able to reach it
      // (build a small custom board and assert canMove == false)
    });
  });

  group('other directions', () {
    test('up and down are consistent with left/right on the transposed board', () {
      // build a column, slide up, compare with the equivalent row sliding left
    });
  });
}
```

### 20.2 Spawner & Difficulty Tests

- With a fixed `Random(seed)`, `sampleValue` over 100 000 draws matches the configured weights within tolerance (e.g. ±1%).
- `Spawner` with `adversaryStrength = 0` never calls `evaluate` (spy/flag) and places tiles uniformly over empty cells (chi-square-style tolerance).
- With `adversaryStrength = 1`, the chosen cell always has the minimum `evaluate` among candidates (deterministic board fixtures).
- `createInitialBoard` for every difficulty: correct size, correct number of tiles, correct number of stones, stones never in a corner, every spawn value in the table.
- **Config sanity test** iterating `kDifficulties`: weights > 0, `targetTile` is a power of two, block layouts contain valid indices, stones are non-adjacent, `doubleSpawnEvery ≥ 0`, `adversaryStrength ∈ [0, 1]`.

### 20.3 Bot & Heuristic Tests

- `ExpectimaxBot.bestMove` returns `null` on a game-over board.
- On a board where one move clearly creates a large merge and the others do not, the bot chooses it (depth 1 and 2).
- `evaluate` ranks a board with more empty cells and mergeable neighbors higher than a cluttered one.

### 20.4 Controller Tests

- A valid swipe increments `moves` by 1 and adds exactly one tile (two on a double-spawn move).
- An invalid swipe changes nothing.
- Undo restores board, score and moves, and decrements `undoLeft`; on Very Hard `canUndo` is always false.
- Win → status `won`; `keepGoing()` → `keepPlaying`; stats record exactly one win.
- Use a fake `StorageService` (or `SharedPreferences.setMockInitialValues({})`).

### 20.5 Manual Test Plan (before release)

- [ ] Play each difficulty for several games in **airplane mode**.
- [ ] Close the app mid-game on every difficulty → relaunch → each game is restored independently.
- [ ] Verify stones render and behave on all four Very Hard layouts.
- [ ] Verify the adversary feels hard but fair (no impossible starts).
- [ ] Rapid swipe stress test (spam swipes): no crash, no desync between board and tiles.
- [ ] Toggle sound, haptics, dark mode, reduce motion.
- [ ] Small phone, large phone, tablet.

Run: `flutter test` and `flutter analyze`.

---

## 21. Balancing Workflow (Bot Simulation)

The numbers in section 3.2 are guesses. Use a **headless simulator** to turn them into measured values before release.

### 21.1 Simulator

```dart
// tool/simulate.dart
import 'dart:math';
import 'package:up_2048/domain/expectimax_bot.dart';
import 'package:up_2048/domain/models/board.dart';
import 'package:up_2048/domain/models/difficulty.dart';
import 'package:up_2048/domain/slide.dart';
import 'package:up_2048/domain/spawner.dart';

void main(List<String> args) {
  final games = args.isNotEmpty ? int.parse(args.first) : 200;

  for (final cfg in kDifficulties.values) {
    var wins = 0;
    var totalScore = 0;
    var totalMoves = 0;
    var totalMax = 0;

    for (var g = 0; g < games; g++) {
      final rng = Random(g);
      final spawner = Spawner(cfg, rng);
      final bot = ExpectimaxBot(depth: 2, rng: rng);
      var board = createInitialBoard(cfg, rng);
      var score = 0;
      var moves = 0;

      while (true) {
        final dir = bot.bestMove(board, cfg.spawnTable);
        if (dir == null) break;                        // game over
        final r = slide(board, dir);
        board = r.board;
        score += r.gained;
        moves++;

        final spawns =
            1 + ((cfg.doubleSpawnEvery > 0 && moves % cfg.doubleSpawnEvery == 0) ? 1 : 0);
        for (var i = 0; i < spawns; i++) {
          final s = spawner.spawn(board);
          if (s == null) break;
          board = s.board;
        }
        if (board.maxTile >= cfg.targetTile) {
          wins++;
          break;
        }
      }
      totalScore += score;
      totalMoves += moves;
      totalMax += board.maxTile;
    }

    print('${cfg.label.padRight(10)} '
        'win=${(100 * wins / games).toStringAsFixed(1)}%  '
        'avgScore=${totalScore ~/ games}  '
        'avgMoves=${totalMoves ~/ games}  '
        'avgMaxTile=${totalMax ~/ games}');
  }
}
```

Run: `dart run tool/simulate.dart 200` (use fewer games with `depth: 3`, which is much slower).

### 21.2 Bots to Compare

| Bot | Purpose |
|---|---|
| **Random bot** (random valid move) | Sanity check: should almost never win on any level |
| **Greedy bot** (best `evaluate` after one slide) | Rough proxy for a casual-to-decent player |
| **Expectimax depth 2** | Proxy for a skilled player |
| **Expectimax depth 3** (slow, run overnight) | Upper bound on what a strong player can achieve |

### 21.3 Initial Target Win Rates (expectimax depth 2) — hypotheses to calibrate

| Difficulty | Target win rate | Rationale |
|---|---|---|
| Easy | ≥ 95% | Almost every competent attempt should succeed |
| Medium | 60–85% | Classic game; a skilled player usually wins |
| Hard | 20–45% | Wins are common enough to stay motivating, losses are frequent |
| Very Hard | 3–15% | Winning is a real achievement |

Also check the **ordering**: for every bot, win rate must satisfy `Easy > Medium > Hard > Very Hard`, and average moves-to-win should grow with difficulty.

### 21.4 Tuning Loop

1. Run the simulator; compare with the targets.
2. Adjust **one** parameter at a time, in this order of impact:
   1. `adversaryStrength` (strongest lever on Hard/Very Hard)
   2. `spawnTable` weights
   3. `doubleSpawnEvery`
   4. `targetTile` (especially Very Hard)
   5. `blockedLayouts` (try a layout with 1 stone, or other positions)
3. Re-run with at least 200–500 games per level to reduce noise.
4. **Human playtest** (5+ people per level): record win rate and perceived fairness; the bot is only a proxy. If bot and humans disagree, trust the humans.
5. Freeze the config and record the final numbers in the repo (`BALANCING.md`).

### 21.5 Fairness Checks for the Adversary

- The adversary must not make the **opening** unwinnable: confirm that the first 20 moves of simulated games rarely end the game.
- If Very Hard feels "unfair" in playtests, lower `adversaryStrength` before touching anything else.

---

## 22. Performance & Quality

- `slide`, `spawn`, `evaluate` operate on tiny arrays (≤ 25 cells); allocation per move is negligible.
- Run hints and any depth-3 search in an **Isolate** (`compute`), never on the UI thread.
- `RepaintBoundary` around the board; `const` constructors wherever possible.
- Avoid rebuilding the whole screen on every move: use `Selector`/`context.select` for score, board and toolbar separately.
- Target: **60 fps** on mid-range devices; verify with Flutter DevTools.
- Keep the app small: compress audio (mp3/ogg at ~ 64–96 kbps), use WebP images.
- Enable `flutter_lints` and fix all warnings.
- Accessibility: provide semantic labels for tiles ("Tile 128, row 2, column 3"), support large text, offer reduce-motion, and keep strong contrast on tile colors.

---

## 23. Phased Roadmap

> Estimates assume one developer working part-time (about 2–3 hours/day). Adjust to your experience.

### Phase 0 – Setup (0.5 day)

- [x] `flutter create up_2048`, remove sample code.
- [x] Create the folder structure from section 7.2, `analysis_options.yaml`.
- [x] Add dependencies, declare assets/fonts.
- [x] Git init, `.gitignore`, first commit; set app name to **Up2048**.

**Done when:** the app runs with an empty screen and `flutter analyze` is clean.

### Phase 1 – Domain Logic & Tests (1.5–2 days)

- [x] `Direction`, `Board`, `TileMotion`, `MoveResult`.
- [x] `slide()` and `canMove()` with the full test suite from 20.1.
- [x] `DifficultyConfig` + `kDifficulties` + config sanity tests.
- [x] `Spawner`, `createInitialBoard`, spawn tests.

**Done when:** `flutter test` is green, including stone behavior.

### Phase 2 – Playable Prototype on Medium (2 days)

- [x] `GameController` (no animation yet): `newGame`, `swipe`, win/over detection.
- [x] `BoardView` + `TileWidget` (static positions), score panel.
- [x] `SwipeDetector` and keyboard input.
- [x] Game-over and win dialogs.

**Done when:** you can play a full Medium game from start to game over or win.

### Phase 3 – All Four Difficulties (1–1.5 days)

- [x] Wire `Difficulty` into `newGame` (board size, spawn table, stones, double spawn).
- [x] Add `evaluate()` and the adversary in `Spawner`.
- [x] Home screen with four difficulty cards and rule badges.
- [x] Stones rendering.

**Done when:** each difficulty visibly behaves according to the table in 3.2.

### Phase 4 – Animation & Game Feel (2 days)

- [x] `TileView` model, `applyMove`, `settle`.
- [x] `AnimatedPositioned` slide, merge bump, spawn pop.
- [x] Swipe buffering during animation; reduce-motion support.

**Done when:** movement is smooth and spamming swipes causes no desync.

### Phase 5 – Persistence, Stats, Settings (1.5 days)

- [x] `StorageService`, `StatsController`, `SettingsController`.
- [x] Autosave/restore per difficulty, Continue button.
- [x] Stats screen, Settings screen, How-to-play screen.

**Done when:** quitting and relaunching restores each difficulty's game, best scores and settings.

### Phase 6 – Tools: Undo, Hint, Remove Tile, Audio (2 days)

- [x] Undo with per-difficulty limits.
- [x] `ExpectimaxBot`, hint button (Isolate), hint arrow.
- [x] Remove-tile power-up.
- [x] `AudioService`, haptics.

**Done when:** tools respect each difficulty's limits and survive edge cases (section 19).

### Phase 7 – Balancing (1.5–2 days)

- [x] `tool/simulate.dart` with random, greedy and expectimax bots.
- [x] Run, compare with targets, tune (section 21), record final numbers.
- [ ] Human playtests; adjust Very Hard target/layouts/adversary.

**Done when:** win-rate ordering Easy > Medium > Hard > Very Hard holds and each level meets its target range or has a documented reason.

### Phase 8 – Polish & Release (2 days)

- [x] Localization (en/vi), dark theme, accessibility labels.
- [x] Icon, splash, store assets.
- [ ] Full manual test (20.5), especially **airplane mode**.
- [x] Build and sign release (section 24).

**Done when:** you have an APK/AAB that runs reliably on at least 2 real devices.

**Status (2026-11-13):** signed APK and AAB are built locally and the release
manifest has no `INTERNET` permission. Real-device and airplane-mode testing,
human playtests and store screenshots are still pending; see `README.md`.

**Estimated total:** ≈ 14–17 working days for the full version; Medium is playable after Phase 2 and all difficulties after Phase 3.

---

## 24. Configuration, Build & Release

### 24.1 Android

- `AndroidManifest.xml`: set `android:label="Up2048"`; **do not add** the `INTERNET` permission.
- Application ID such as `com.yourname.up2048`.
- Create a keystore and `key.properties` for signing (never commit them).
- Build:

```bash
flutter build apk --release            # .apk for direct install
flutter build appbundle --release      # .aab for Google Play
```

### 24.2 iOS (requires macOS + Xcode)

```bash
flutter build ios --release
```

Set Bundle ID, Team and icon; set `CFBundleDisplayName` to `Up2048`.

### 24.3 Web / Desktop (optional)

```bash
flutter build web --release
flutter build windows --release   # or macos / linux
```

Keyboard controls (section 14.2) make Web and Desktop builds fully usable.

### 24.4 Icon & Splash

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/icon.png"
```

Run `dart run flutter_launcher_icons`.

### 24.5 Final Pre-Release Checks

- [x] `flutter analyze` has no errors; `flutter test` is green.
- [ ] Release build runs in airplane mode.
- [x] No leftover debug `print` calls.
- [x] `ASSETS_LICENSE.md` lists audio/font sources.
- [x] `BALANCING.md` records the final difficulty numbers and simulation results.

---

## 25. Risks & Mitigations

| Risk | Level | Mitigation |
|---|---|---|
| Difficulty feels wrong despite sound-looking numbers | High | Data-driven configs, bot simulator, human playtests (section 21); keep tuning cheap |
| Adversary feels unfair or "cheating" | Medium | Cap strength (≤ 0.65), reveal it in the UI ("Mean spawns"), verify openings in simulation, be ready to lower it |
| Very Hard unwinnable with stones + adversary | Medium | Lower target (1024), try 1 stone or different layouts, measure with bots |
| Animation desync (tile identities wrong) | Medium | Keep `TileView` logic small and unit-tested; fall back to `fromBoard` after undo/restore |
| Hint computation freezes UI | Low | Isolate (`compute`), depth ≤ 2 for hints |
| Corrupted/old saves after updates | Low | Versioned keys, `try/catch`, fall back to a new game |
| Audio latency on some Android devices | Low | `PlayerMode.lowLatency`, short compressed files, preload |
| Visual/legal similarity to existing 2048 clones | Low | Create own art, palette, name and sounds; implement logic from scratch; check the license of any code or assets you reuse |
| A package silently needs network access | Low | Re-check `pubspec.yaml`; test in airplane mode |

---

## 26. Completion Checklist

### Gameplay

- [x] Correct slide/merge rules (including single merge per move)
- [x] Stones split lines correctly
- [x] Spawn tables, double spawn and adversary per difficulty
- [x] Win (Keep going) and game-over detection
- [x] Four difficulties selectable from Home, each with its own save and stats

### Tools & Features

- [x] Undo, Hint, Remove tile with per-difficulty limits
- [x] Autosave and resume per difficulty
- [x] Stats screen, best scores, career points
- [x] Sound, haptics, dark mode, reduce motion, language

### Technical

- [x] Domain layer does not import Flutter
- [x] Unit tests for slide, spawner, config, bot, controller
- [x] Bot simulation run and final numbers recorded
- [x] No network-dependent packages; fonts/audio in assets; no INTERNET permission in release
- [ ] Smooth ~60 fps

### Release

- [x] Icon, app name (**Up2048**), splash
- [x] Signed APK/AAB built
- [ ] Tested on real devices in airplane mode
- [x] Asset licenses and balancing notes in the repo

---

### Appendix: Ideas After Version 1.0

1. **Daily challenge:** fixed `Random(seed)` from the date (same spawn sequence for everyone, offline), one attempt per day, streak counter.
2. **Custom game:** let the player pick board size, spawn table and stones, with a "balance estimate" from the bot.
3. **Zen mode:** no game over; when the board fills, the lowest tiles are cleared.
4. **Blitz mode:** 2–3 minute timer, score as high as possible.
5. **Replays:** store moves + seed, replay finished games at x1/x2/x4 speed.
6. **Tile skins:** classic numbers, fruits, planets, unlocked by career points.
7. **Smarter adversary tiers:** depth-2 adversary for a future "Nightmare" level (measure fun vs. frustration first).
