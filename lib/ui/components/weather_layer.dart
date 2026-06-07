import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/new_home/weather_cubit.dart';
import 'package:guachinches/data/services/weather_service.dart';
import 'package:guachinches/ui/components/clouds_overlay.dart';
import 'package:guachinches/ui/components/rain_overlay.dart';

/// Layer meteorológico sobre el hero: compone nubes/lluvia según la
/// condición meteorológica de la zona seleccionada.
///
/// Deriva la condición de la MISMA fuente que el chip del `TopFilterBar`
/// (el [WeatherCubit], que consulta el backend por isla/zona/municipio), de
/// modo que ambos quedan siempre sincronizados: al cambiar a una zona soleada
/// el chip pasa a ☀️ y las nubes desaparecen en el mismo frame.
///
/// Pensado para colocarse dentro de un `Stack` con `Clip.hardEdge`.
class WeatherLayer extends StatelessWidget {
  const WeatherLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherCubit, WeatherState>(
      builder: (context, state) {
        final condition = state is WeatherLoaded
            ? _conditionFromBackend(state.data.condition)
            : WeatherCondition.unknown;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: _buildOverlay(condition),
        );
      },
    );
  }

  /// Mapea la `condition` textual del backend
  /// ('sunny' | 'cloudy' | 'rain' | 'fog' | 'storm' | 'unknown') al enum
  /// visual que consumen los overlays.
  static WeatherCondition _conditionFromBackend(String condition) {
    switch (condition) {
      case 'sunny':
        return WeatherCondition.clear;
      case 'cloudy':
        return WeatherCondition.cloudy;
      case 'rain':
        return WeatherCondition.rain;
      case 'fog':
        return WeatherCondition.fog;
      case 'storm':
        return WeatherCondition.thunderstorm;
      default:
        return WeatherCondition.unknown;
    }
  }

  Widget _buildOverlay(WeatherCondition condition) {
    if (!condition.hasClouds && !condition.hasRain) {
      return const SizedBox.shrink(key: ValueKey('clear'));
    }
    return Stack(
      key: ValueKey(condition),
      children: [
        if (condition.hasClouds)
          Positioned.fill(
            child: IgnorePointer(
              child: CloudsOverlay(
                opacity: condition.cloudIntensity,
                count: condition == WeatherCondition.cloudy ||
                        condition == WeatherCondition.heavyRain ||
                        condition == WeatherCondition.thunderstorm
                    ? 6
                    : 4,
              ),
            ),
          ),
        if (condition.hasRain)
          Positioned.fill(
            child: IgnorePointer(
              child: RainOverlay(
                density: condition.rainDensity,
                tilt: condition.rainTilt,
                opacity: switch (condition) {
                  WeatherCondition.drizzle => 0.20,
                  WeatherCondition.rain => 0.30,
                  WeatherCondition.heavyRain => 0.38,
                  WeatherCondition.thunderstorm => 0.45,
                  _ => 0.30,
                },
              ),
            ),
          ),
      ],
    );
  }
}
