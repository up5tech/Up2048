import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_controller.dart';
import '../../core/tile_palette.dart';
import '../../l10n/app_localizations.dart';

/// Branded launch screen shown while the app settles (PLAN.md §13.2).
///
/// Settings and stats are already loaded before `runApp`, so this is only a
/// short minimum-display splash. It intentionally contains no looping
/// animation: `reduceMotion` skips it entirely and widget tests can settle.
class SplashScreen extends StatefulWidget {
  final Widget child;

  const SplashScreen({super.key, required this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minDisplay = Duration(milliseconds: 700);

  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    final reduceMotion =
        context.read<SettingsController>().settings.reduceMotion;
    _ready = Future<void>.delayed(reduceMotion ? Duration.zero : _minDisplay);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return widget.child;
        }
        return _buildSplash(context);
      },
    );
  }

  Widget _buildSplash(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF2B2D42) : const Color(0xFFE8F1F2);
    final foreground = dark ? const Color(0xFFE8F1F2) : const Color(0xFF2B2D42);

    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: Semantics(
          key: const ValueKey('splash_content'),
          label: AppLocalizations.of(context).appTitle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SplashLogo(size: 176),
              const SizedBox(height: 28),
              Text(
                AppLocalizations.of(context).appTitle,
                style: TextStyle(
                  color: foreground,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The same 2×2 tile grid as the launcher icon, drawn with widgets so the
/// splash needs no bundled image and scales cleanly on tablets.
class _SplashLogo extends StatelessWidget {
  final double size;

  const _SplashLogo({required this.size});

  static const _values = [2, 4, 8, 32];

  @override
  Widget build(BuildContext context) {
    final gap = size * 0.064;
    final tile = (size - gap) / 2;

    Widget cell(int value) {
      final colors = colorsForTile(value);
      return Container(
        width: tile,
        height: tile,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(tile * 0.18),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            color: colors.foreground,
            fontSize: tile * (value >= 10 ? 0.36 : 0.46),
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              cell(_values[0]),
              SizedBox(width: gap),
              cell(_values[1]),
            ],
          ),
          SizedBox(height: gap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              cell(_values[2]),
              SizedBox(width: gap),
              cell(_values[3]),
            ],
          ),
        ],
      ),
    );
  }
}
