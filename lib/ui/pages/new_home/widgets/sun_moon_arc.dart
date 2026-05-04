import 'dart:math';
import 'package:flutter/material.dart';
import 'package:guachinches/utils/time_of_day_engine.dart';

/// Emoji de sol o luna animado en arco sobre el hero.
/// 6h–20h → sol; resto → luna.
class SunMoonArc extends StatelessWidget {
  final int hour;
  final double heroWidth;
  final double heroHeight;

  const SunMoonArc({
    super.key,
    required this.hour,
    required this.heroWidth,
    required this.heroHeight,
  });

  _ArcPosition _computePosition() {
    final double x, y;
    if (hour >= 6 && hour < 20) {
      final t = (hour - 6) / 14.0;
      x = t * (heroWidth - 40) + 10;
      y = heroHeight * 0.65 - sin(t * pi) * heroHeight * 0.52;
    } else {
      final t = hour >= 20 ? (hour - 20) / 8.0 : (hour + 4) / 8.0;
      x = t * (heroWidth - 40) + 10;
      y = heroHeight * 0.12;
    }
    return _ArcPosition(x: x.clamp(6.0, heroWidth - 30), y: y.clamp(8.0, heroHeight - 30));
  }

  @override
  Widget build(BuildContext context) {
    final pos = _computePosition();
    final emoji = TimeOfDayEngine.sunEmoji(hour);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.elasticOut,
      left: pos.x,
      top: pos.y,
      child: IgnorePointer(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class _ArcPosition {
  final double x, y;
  const _ArcPosition({required this.x, required this.y});
}
