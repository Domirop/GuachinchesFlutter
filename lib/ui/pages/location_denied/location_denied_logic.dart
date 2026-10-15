import 'package:guachinches/data/cubit/location/location_state.dart';

/// Lógica pura de «Ubicación denegada» (tablero `UbicacionDenegada`):
/// qué variante y qué textos según el estado y la plataforma. En iOS se dice
/// siempre «Localización» (como en Ajustes); en Android, «Ubicación» y nunca
/// «iPhone».

enum LocationDeniedVariant {
  /// Sin permiso para la app (denegado o denegado para siempre).
  permission,

  /// Servicio de localización apagado en todo el dispositivo.
  service,
}

LocationDeniedVariant locationDeniedVariantFor(LocationState s) =>
    s is LocationServiceDisabled
        ? LocationDeniedVariant.service
        : LocationDeniedVariant.permission;

/// Icono de cada paso (tinte suave detrás).
enum DeniedStepIcon { gear, hand, locate, check, target }

/// Tinte del icono: neutro (`fill`), acción (`accentSoft`), ok y aviso.
enum DeniedStepTint { neutral, accent, ok, warn }

class DeniedStep {
  final String label;
  final DeniedStepIcon icon;
  final DeniedStepTint tint;

  /// Pinta un interruptor encendido (lo que el usuario debe activar).
  final bool toggle;

  const DeniedStep(this.label, this.icon, this.tint, {this.toggle = false});
}

class LocationDeniedCopy {
  final String eyebrow;
  final String title;
  final String text;
  final List<DeniedStep> steps;

  /// Nota final (solo en la variante de permiso).
  final String? footnote;

  const LocationDeniedCopy({
    required this.eyebrow,
    required this.title,
    required this.text,
    required this.steps,
    this.footnote,
  });
}

const String kDeniedFootnote =
    'Sin ubicación también funciona: elige zona en el Inicio y ordenamos por '
    'valoración.';

LocationDeniedCopy locationDeniedCopy(LocationDeniedVariant v,
    {required bool isIOS}) {
  if (isIOS) {
    if (v == LocationDeniedVariant.service) {
      return const LocationDeniedCopy(
        eyebrow: 'Localización apagada en el iPhone',
        title: 'Enciende la localización',
        text: 'Está apagada para todo el iPhone. Enciéndela y te enseñamos lo '
            'abierto cerca de ti y a cuántos minutos está.',
        steps: [
          DeniedStep(
              'Abre Ajustes', DeniedStepIcon.gear, DeniedStepTint.neutral),
          DeniedStep('Privacidad y seguridad', DeniedStepIcon.hand,
              DeniedStepTint.accent),
          DeniedStep(
              'Localización', DeniedStepIcon.locate, DeniedStepTint.accent),
          DeniedStep(
              'Activa «Localización»', DeniedStepIcon.check, DeniedStepTint.ok,
              toggle: true),
        ],
      );
    }
    return const LocationDeniedCopy(
      eyebrow: 'Sin permiso de localización',
      title: 'Deja que veamos dónde estás',
      text: 'Al tocar «Abrir Ajustes» llegas directo a los ajustes de Dónde '
          'Comer. Allí:',
      steps: [
        DeniedStep('Toca «Localización»', DeniedStepIcon.locate,
            DeniedStepTint.accent),
        DeniedStep('Elige «Cuando se use la app»', DeniedStepIcon.check,
            DeniedStepTint.ok),
        DeniedStep('Activa «Ubicación exacta»', DeniedStepIcon.target,
            DeniedStepTint.warn,
            toggle: true),
      ],
      footnote: kDeniedFootnote,
    );
  }
  // Android: «Abrir Ajustes» lleva a los ajustes de ubicación del sistema
  // (servicio) o a la información de la app (permiso).
  if (v == LocationDeniedVariant.service) {
    return const LocationDeniedCopy(
      eyebrow: 'Ubicación apagada en el móvil',
      title: 'Activa la ubicación',
      text: 'Está apagada para todo el móvil. Al tocar «Abrir Ajustes» llegas '
          'directo a los ajustes de ubicación. Allí:',
      steps: [
        DeniedStep(
            'Activa «Usar ubicación»', DeniedStepIcon.check, DeniedStepTint.ok,
            toggle: true),
      ],
    );
  }
  return const LocationDeniedCopy(
    eyebrow: 'Sin permiso de ubicación',
    title: 'Deja que veamos dónde estás',
    text: 'Al tocar «Abrir Ajustes» llegas directo a la información de Dónde '
        'Comer. Allí:',
    steps: [
      DeniedStep(
          'Toca «Permisos»', DeniedStepIcon.gear, DeniedStepTint.neutral),
      DeniedStep(
          'Toca «Ubicación»', DeniedStepIcon.locate, DeniedStepTint.accent),
      DeniedStep('Elige «Permitir solo mientras se usa la aplicación»',
          DeniedStepIcon.check, DeniedStepTint.ok),
      DeniedStep('Activa «Usar ubicación precisa»', DeniedStepIcon.target,
          DeniedStepTint.warn,
          toggle: true),
    ],
    footnote: kDeniedFootnote,
  );
}
