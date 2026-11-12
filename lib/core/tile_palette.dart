import 'package:flutter/material.dart';

/// Tile colors from PLAN.md §13.3 (original palette).
class TileColors {
  final Color background;
  final Color foreground;
  const TileColors(this.background, this.foreground);
}

const Color kBoardBackground = Color(0xFFBBADA0);
const Color kEmptyCellColor = Color(0xFFCDC1B4);
const Color kStoneColor = Color(0xFF776E65);
const Color kStoneIconColor = Color(0xFF5D554C);

const Map<int, TileColors> kTilePalette = {
  2: TileColors(Color(0xFFE8F1F2), Color(0xFF3A4A55)),
  4: TileColors(Color(0xFFCFE8EF), Color(0xFF3A4A55)),
  8: TileColors(Color(0xFF9AD1D4), Color(0xFF1F2D3A)),
  16: TileColors(Color(0xFF6FB7C4), Color(0xFFFFFFFF)),
  32: TileColors(Color(0xFF4F9DB8), Color(0xFFFFFFFF)),
  64: TileColors(Color(0xFF3F7FB5), Color(0xFFFFFFFF)),
  128: TileColors(Color(0xFF6A6BC9), Color(0xFFFFFFFF)),
  256: TileColors(Color(0xFF8E5BC7), Color(0xFFFFFFFF)),
  512: TileColors(Color(0xFFB24FB8), Color(0xFFFFFFFF)),
  1024: TileColors(Color(0xFFD9479A), Color(0xFFFFFFFF)),
  2048: TileColors(Color(0xFFF2A33A), Color(0xFFFFFFFF)),
};

const TileColors kSuperTileColors =
    TileColors(Color(0xFF2B2D42), Color(0xFFFFD166));

TileColors colorsForTile(int value) =>
    kTilePalette[value] ?? kSuperTileColors;

/// Font size factor by digit count (PLAN.md §13.3).
double fontScaleFor(int value) {
  final digits = value.abs().toString().length;
  if (digits <= 2) return 1.0;
  if (digits == 3) return 0.8;
  return 0.65;
}
