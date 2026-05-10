import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/services/weather_service.dart';
import 'package:guachinches/ui/components/clouds_overlay.dart';
import 'package:guachinches/ui/components/rain_overlay.dart';

/// Layer meteorológico: consulta el tiempo actual con Open-Meteo y compone
/// nubes/lluvia/etc. encima del hero. Pensado para colocarse dentro de un
/// `Stack` con `Clip.hardEdge`.
///
/// Si no se pasa `lat`/`lon` explícito, usa la posición del `LocationCubit`
/// global y, en su defecto, Santa Cruz de Tenerife.
class WeatherLayer extends StatefulWidget {
  final double? lat;
  final double? lon;

  const WeatherLayer({super.key, this.lat, this.lon});

  @override
  State<WeatherLayer> createState() => _WeatherLayerState();
}

class _WeatherLayerState extends State<WeatherLayer> {
  WeatherCondition _condition = WeatherCondition.unknown;
  bool _fetching = false;

  // Fallback: centro de Tenerife si no hay GPS y no se pasa explícito.
  static const double _fallbackLat = 28.4682;
  static const double _fallbackLon = -16.2546;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  (double, double) _resolveCoords() {
    if (widget.lat != null && widget.lon != null) {
      return (widget.lat!, widget.lon!);
    }
    final s = context.read<LocationCubit>().state;
    if (s is LocationLoaded) return (s.latitude, s.longitude);
    return (_fallbackLat, _fallbackLon);
  }

  Future<void> _fetch() async {
    if (_fetching) return;
    _fetching = true;
    final (lat, lon) = _resolveCoords();
    final cond = await WeatherService.instance
        .currentCondition(lat: lat, lon: lon);
    if (!mounted) return;
    setState(() {
      _condition = cond;
      _fetching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationCubit, LocationState>(
      listenWhen: (prev, curr) =>
          curr is LocationLoaded && prev is! LocationLoaded,
      listener: (_, __) => _fetch(),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _buildOverlay(),
      ),
    );
  }

  Widget _buildOverlay() {
    if (!_condition.hasClouds && !_condition.hasRain) {
      return const SizedBox.shrink(key: ValueKey('clear'));
    }
    return Stack(
      key: ValueKey(_condition),
      children: [
        if (_condition.hasClouds)
          Positioned.fill(
            child: IgnorePointer(
              child: CloudsOverlay(
                opacity: _condition.cloudIntensity,
                count: _condition == WeatherCondition.cloudy ||
                        _condition == WeatherCondition.heavyRain ||
                        _condition == WeatherCondition.thunderstorm
                    ? 6
                    : 4,
              ),
            ),
          ),
        if (_condition.hasRain)
          Positioned.fill(
            child: IgnorePointer(
              child: RainOverlay(
                density: _condition.rainDensity,
                tilt: _condition.rainTilt,
                opacity: switch (_condition) {
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
