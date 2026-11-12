import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/tile_palette.dart';

class TileWidget extends StatelessWidget {
  final int value;
  final double size;
  final bool isStone;
  final bool isNew;
  final bool isMerged;
  final bool isGhost;
  final bool reduceMotion;

  const TileWidget({
    super.key,
    required this.value,
    required this.size,
    this.isStone = false,
    this.isNew = false,
    this.isMerged = false,
    this.isGhost = false,
    this.reduceMotion = false,
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
    final face = Opacity(
      // Ghosts are the two tiles sliding into a merge; they fade out under
      // the merged tile once the slide finishes.
      opacity: isGhost ? 0.65 : 1,
      child: Container(
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
      ),
    );

    if (reduceMotion || (!isNew && !isMerged)) return face;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: isNew ? 240 : 150),
      builder: (context, t, child) {
        final scale = isNew
            // Let the slide finish (first 45% of the window), then pop in.
            ? Curves.easeOutBack.transform(Interval(0.45, 1.0).transform(t))
            // Merge: one bump 1 → 1.15 → 1.
            : 1 + 0.14 * math.sin(math.pi * t);
        return Transform.scale(scale: scale.clamp(0.01, 1.3), child: child);
      },
      child: face,
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
