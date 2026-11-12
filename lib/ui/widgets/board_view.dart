import 'package:flutter/material.dart';

import '../../core/tile_palette.dart';
import '../../domain/models/board.dart';
import 'tile_widget.dart';

/// Static board renderer (Phase 2). Phase 4 swaps in TileView +
/// AnimatedPositioned for slide/merge/spawn animation.
class BoardView extends StatelessWidget {
  final Board board;

  const BoardView({super.key, required this.board});

  static const double _gapRatio = 0.025; // gap as fraction of cell pitch

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = board.size;
        // Square board: min(width, height × 0.6 of available space).
        final side =
            constraints.maxWidth < constraints.maxHeight * 0.75
                ? constraints.maxWidth
                : constraints.maxHeight * 0.75;
        final gap = side * _gapRatio / (n + _gapRatio * n);
        final cell = (side - gap * (n + 1)) / n;

        return RepaintBoundary(
          child: Container(
            width: side,
            height: side,
            padding: EdgeInsets.all(gap),
            decoration: BoxDecoration(
              color: kBoardBackground,
              borderRadius: BorderRadius.circular(gap * 2),
            ),
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
                for (var i = 0; i < board.cells.length; i++)
                  if (board.cells[i] > 0)
                    Positioned(
                      left: (i % n) * (cell + gap),
                      top: (i ~/ n) * (cell + gap),
                      width: cell,
                      height: cell,
                      child: TileWidget(value: board.cells[i], size: cell),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
