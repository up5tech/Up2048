import 'package:flutter/material.dart';

import '../../core/tile_palette.dart';
import '../../domain/models/board.dart';
import '../../domain/models/tile_view.dart';
import 'tile_widget.dart';

/// Board renderer with animated slide, merge and spawn (PLAN.md §15.2).
class BoardView extends StatelessWidget {
  final Board board;
  final List<TileView> tiles;
  final bool reduceMotion;

  const BoardView({
    super.key,
    required this.board,
    required this.tiles,
    this.reduceMotion = false,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
