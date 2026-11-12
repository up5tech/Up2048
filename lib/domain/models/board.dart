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
