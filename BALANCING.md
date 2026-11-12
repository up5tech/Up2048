# Balancing — measured difficulty numbers

Source of truth for the shipped values. PLAN.md §3.2 held the **starting
hypotheses**; the numbers below are what `tool/simulate.dart` measured and are
what the game actually uses.

Measured with Flutter's headless simulator (`dart run tool/simulate.dart ...`),
**expectimax depth 2, 6 chance samples, 100 games per level, seeds 0–99**, on
the final heuristic. Human playtests (PLAN.md §21.4 step 4) are still pending.

## Final measurements (calibration bot)

| Level | Win rate | Target (PLAN §21.3) | Avg score | Avg moves | Avg max tile |
|---|---|---|---|---|---|
| Easy | **100.0%** | ≥95% | 21 307 | 1 032 | 2048 |
| Medium | **46.0%** | 60–85% | 17 175 | 920 | 1428 |
| Hard | **24.0%** | 20–45% | 13 018 | 595 | 1080 |
| Very Hard | **8.0%** | 3–15% | 1 669 | 113 | 159 |

Ordering `Easy > Medium > Hard > Very Hard` **holds**.

Sanity bots (not calibration targets, only a smell test):

| Bot | Easy | Medium | Hard | Very Hard |
|---|---|---|---|---|
| Greedy (`--bot=greedy`, 300 games) | 71.3% | 0.0% | 0.0% | 0.3% |
| Random (`--bot=random`, 300 games) | 0.0% | 0.0% | 0.0% | 0.0% |

Random play wins nothing on any level, and a one-ply greedy bot only wins Easy:
the levels do reward real structure.

## Final config values

Bold cells differ from PLAN.md §3.2.

| Parameter | Easy | Medium | Hard | Very Hard |
|---|---|---|---|---|
| Board | 5 × 5 | 4 × 4 | 4 × 4 | 4 × 4 + **2 stones** |
| Target tile | 2048 | 2048 | 2048 | **512** |
| Spawn table | 2 (90%), 4 (10%) | 2 (90%), 4 (10%) | **2 (77%), 4 (20%), 8 (3%)** | **2 (70%), 4 (25%), 8 (5%)** |
| Initial tiles | 2 | 2 | 3 | 4 |
| Double spawn | never | never | every 10th move | **every 9th move** |
| Adversary strength | 0 | 0 | **0.10** | **0.35** |
| Undo per game | 10 | 3 | 1 | 0 |
| Hints per game | 5 | 2 | 0 | 0 |
| Remove-tile per game | 3 | 1 | 0 | 0 |
| Score multiplier | ×0.5 | ×1 | ×1.5 | ×2 |

## Deviations from PLAN §3.2 and why

1. **Very Hard target 1024 → 512.** With two stones the bot topped out around
   128–266 regardless of spawn tuning: 1024 never happened in 60-game runs, at
   adversary 0.65, 0.35, one stone, or reduced double spawns. PLAN §3.2 itself
   flagged this target as the first thing to revisit. 512 plus two stones,
   extra tiles and mean spawns lands at the intended 3–15%.
2. **Very Hard double spawn every 5 → every 9, spawn table 55/35/10 →
   70/25/5, adversary 0.65 → 0.35.** Each step moved the average max tile up
   (137 → 266) but only the target change made wins possible; the softer
   numbers keep the level hostile without making every run a coin flip.
3. **Hard adversary 0.25 → 0.10 and spawn table 70/25/5 → 77/20/3.** At 0.25
   the bot won 16.7–20% (bottom edge or just below target); removing the
   adversary entirely gave 30%, so 0.10 sits mid-range at 24%. The 8 spawns
   stay, just rarer, so Hard keeps its "8s can appear" character.
4. **Medium is untouched (classic 4×4, 90/10, 2048) but measures 46%**, below
   the 60–85% hypothesis. Reason: the depth-2 bot is the limiting factor, not
   the ruleset — a 10-game depth-3 run measured 50% (within noise of depth 2),
   and the classic ruleset is by definition the reference experience. Treated
   as a documented deviation per the Phase 7 completion criteria; a human
   playtest should decide whether Medium needs any help.

## Heuristic changes made during balancing

`evaluate()` (PLAN §11.1) drives hints, the simulator and the adversary, so it
was tuned first — the original weights won only 7% on Medium.

- Added a **monotonicity** term (best direction per row/column, stones and
  empty cells break runs): Medium 7% → 38%.
- Reweighted and made merges log-weighted (merging big tiles counts more):
  `empty 500 · mergeable 60 · smoothness 12 · monotonicity 150 · maxTile 20 ·
  corner 200 × log2(maxTile)`: Medium → 55% on a 40-game sample, 46% on the
  100-game run.
- Chance-node sampling above 6 cells (`--samples=10`) changed nothing
  (50% vs 55%, within noise), so the default stays at 6 — cheaper hints.
- `log2` is now computed exactly as `bitLength - 1` and `evaluate` avoids list
  allocation, which made it ~2× faster (2.1 s → 1.4 s per Easy game). That
  keeps the in-game hint fast.

## Tuning log (one lever at a time, PLAN §21.4 order)

| Step | Change | Measured |
|---|---|---|
| Baseline | PLAN §3.2 values, original heuristic | Easy 99 · Medium 7 · Hard 0 · VH 0 |
| Heuristic | + monotonicity | Medium 38 |
| Heuristic | weights v2 (empty 350, mono 100) | Medium 37 |
| Heuristic | weights v3 (empty 500, mono 150) | Medium 55 (40 games) |
| Heuristic | chance samples 6 → 10 | Medium 50 (discarded) |
| Very Hard | adversary 0.65 → 0.35 | 0%, avg max 124 |
| Very Hard | double spawn 5 → 9 | 0%, avg max 137 |
| Very Hard | 2 stones → 1 stone | 0%, avg max 266 |
| Very Hard | spawn table → 70/25/5 (1 stone) | 0%, avg max 265 |
| Very Hard | 2 stones restored + target 512 | **10%** |
| Hard | adversary 0.25 baseline | 20.0 (60 games) |
| Hard | adversary 0.2 | 16.7 (noise) |
| Hard | double spawn 10 → 15 | 15.0 |
| Hard | spawn table 77/20/3 | 16.7 |
| Hard | adversary 0 | 30.0 |
| Hard | adversary 0.10 | 21.7 → **24.0** (100 games) |

## Reproducing

```bash
dart run tool/simulate.dart 100                       # calibration bot
dart run tool/simulate.dart 300 --bot=greedy          # casual proxy
dart run tool/simulate.dart 300 --bot=random          # sanity check
dart run tool/simulate.dart 40 --difficulty=hard --depth=3   # slow upper bound
```

Simulation is fully seeded (`Random(seed)` per game), so these numbers are
reproducible on any machine. If bots and human playtests disagree, trust the
humans (PLAN §21.4).
