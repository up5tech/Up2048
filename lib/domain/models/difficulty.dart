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
  final int doubleSpawnEvery; // 0 = never
  final double adversaryStrength; // 0..1
  final int undoLimit; // -1 = unlimited
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
    spawnTable: [SpawnWeight(2, 77), SpawnWeight(4, 20), SpawnWeight(8, 3)],
    initialTiles: 3,
    doubleSpawnEvery: 10,
    adversaryStrength: 0.1,
    undoLimit: 1,
    hintLimit: 0,
    removeTileLimit: 0,
    scoreMultiplier: 1.5,
  ),
  Difficulty.veryHard: DifficultyConfig(
    id: Difficulty.veryHard,
    label: 'Very Hard',
    boardSize: 4,
    targetTile: 512,
    spawnTable: [SpawnWeight(2, 70), SpawnWeight(4, 25), SpawnWeight(8, 5)],
    initialTiles: 4,
    // Row-major indices on a 4x4 board. All are non-corner and non-adjacent.
    blockedLayouts: [
      [5, 10], // (1,1) and (2,2)
      [6, 9], // (1,2) and (2,1)
      [1, 14], // (0,1) and (3,2)
      [4, 11], // (1,0) and (2,3)
    ],
    doubleSpawnEvery: 9,
    adversaryStrength: 0.35,
    undoLimit: 0,
    hintLimit: 0,
    removeTileLimit: 0,
    scoreMultiplier: 2.0,
  ),
};
