import 'package:flutter/material.dart';

import '../../core/tile_palette.dart';

class TileWidget extends StatelessWidget {
  final int value;
  final double size;
  final bool isStone;

  const TileWidget({
    super.key,
    required this.value,
    required this.size,
    this.isStone = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isStone) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: kStoneColor,
          borderRadius: BorderRadius.circular(size * 0.08),
        ),
        child: Icon(
          Icons.hexagon_outlined,
          color: kStoneIconColor,
          size: size * 0.45,
        ),
      );
    }

    final colors = colorsForTile(value);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(size * 0.08),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.08),
          child: Text(
            '$value',
            style: TextStyle(
              color: colors.foreground,
              fontSize: size * 0.42 * fontScaleFor(value),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty background cell.
class EmptyCell extends StatelessWidget {
  final double size;
  const EmptyCell({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kEmptyCellColor,
        borderRadius: BorderRadius.circular(size * 0.08),
      ),
    );
  }
}
