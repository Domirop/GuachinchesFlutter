import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/new_home/widgets/parallax_hero.dart';

/// Posiciona el hero con efecto parallax sin reconstruirlo en cada tick.
///
/// Usa [ValueListenableBuilder] con el hero en el parámetro `child:` para que
/// Flutter reutilice el subárbol del hero (foto CachedNetworkImage, WeatherLayer,
/// starfield, sol/luna) entre frames de scroll. El `builder` solo recalcula la
/// posición y el tamaño del [Positioned] que envuelve al hero.
///
/// Debe usarse como hijo de un [Stack].
class ParallaxHeroSlot extends StatelessWidget {
  final ValueListenable<double> offset;
  final Widget child;

  const ParallaxHeroSlot({
    super.key,
    required this.offset,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: offset,
      child: RepaintBoundary(child: child),
      builder: (_, value, heroChild) {
        final scrollUp = math.max(value, 0.0);
        final overscroll = math.max(-value, 0.0);
        return Positioned(
          top: -scrollUp,
          left: 0,
          right: 0,
          height: kHeroHeight + overscroll,
          child: heroChild!,
        );
      },
    );
  }
}
