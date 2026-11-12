import 'package:flutter/material.dart';

import '../../domain/models/direction.dart';

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
