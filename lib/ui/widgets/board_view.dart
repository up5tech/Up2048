import 'package:flutter/material.dart';

import '../../core/tile_palette.dart';
import '../../domain/models/board.dart';
import '../../domain/models/direction.dart';
import '../../domain/models/tile_view.dart';
import 'tile_widget.dart';

/// Board renderer with animated slide, merge and spawn (PLAN.md §15.2).
class BoardView extends StatelessWidget {
  final Board board;
  final List<TileView> tiles;
  final bool reduceMotion;

  /// Direction suggested by the AI hint, if any.
  final Direction? hint;

  /// Called with the row-major cell index when the player taps a cell.
  final void Function(int index)? onCellTap;

  const BoardView({
    super.key,
    required this.board,
    required this.tiles,
    this.reduceMotion = false,
    this.hint,
    this.onCellTap,
  });

  static const double _gapRatio = 0.025; // gap as fraction of cell pitch

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = board.size;
        // Square board: min(width, height × 0.75 of available space).
        final side = constraints.maxWidth < constraints.maxHeight * 0.75
            ? constraints.maxWidth
            : constraints.maxHeight * 0.75;
        final gap = side * _gapRatio / (n + _gapRatio * n);
        final cell = (side - gap * (n + 1)) / n;
        final slideMs = reduceMotion ? 0 : 120;

        // Ghosts paint first so the merged tile lands on top of them.
        final ordered = [
          for (final t in tiles)
            if (t.isGhost) t,
          for (final t in tiles)
            if (!t.isGhost) t,
        ];

        return RepaintBoundary(
          child: Container(
            width: side,
            height: side,
            padding: EdgeInsets.all(gap),
            decoration: BoxDecoration(
              color: kBoardBackground,
              borderRadius: BorderRadius.circular(gap * 2),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: onCellTap == null
                  ? null
                  : (details) => _handleTap(details, n, cell, gap),
              child: Stack(
                children: [
                  // Background layer: empty cells and stones.
                  for (var i = 0; i < board.cells.length; i++)
                    Positioned(
                      left: (i % n) * (cell + gap),
                      top: (i ~/ n) * (cell + gap),
                      width: cell,
                      height: cell,
                      child: board.cells[i] == kBlock
                          ? TileWidget(value: 0, size: cell, isStone: true)
                          : EmptyCell(size: cell),
                    ),
                  // Tile layer.
                  for (final t in ordered)
                    AnimatedPositioned(
                      key: ValueKey<int>(t.id),
                      duration: Duration(milliseconds: slideMs),
                      curve: Curves.easeOut,
                      left: (t.index % n) * (cell + gap),
                      top: (t.index ~/ n) * (cell + gap),
                      width: cell,
                      height: cell,
                      child: TileWidget(
                        value: t.value,
                        size: cell,
                        isNew: t.isNew,
                        isMerged: t.isMerged,
                        isGhost: t.isGhost,
                        reduceMotion: reduceMotion,
                      ),
                    ),
                  // Hint arrow on the edge the bot suggests sliding toward.
                  if (hint != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Align(
                          alignment: _hintAlignment(hint!),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _hintIcon(hint!),
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(TapUpDetails details, int n, double cell, double gap) {
    final callback = onCellTap;
    if (callback == null) return;
    final pitch = cell + gap;
    final dx = details.localPosition.dx;
    final dy = details.localPosition.dy;
    final col = dx ~/ pitch;
    final row = dy ~/ pitch;
    if (col < 0 || col >= n || row < 0 || row >= n) return;
    // Ignore taps that land in the gap between cells.
    if (dx - col * pitch > cell || dy - row * pitch > cell) return;
    callback(row * n + col);
  }

  static Alignment _hintAlignment(Direction d) => switch (d) {
        Direction.up => Alignment.topCenter,
        Direction.down => Alignment.bottomCenter,
        Direction.left => Alignment.centerLeft,
        Direction.right => Alignment.centerRight,
      };

  static IconData _hintIcon(Direction d) => switch (d) {
        Direction.up => Icons.keyboard_arrow_up,
        Direction.down => Icons.keyboard_arrow_down,
        Direction.left => Icons.keyboard_arrow_left,
        Direction.right => Icons.keyboard_arrow_right,
      };
}
