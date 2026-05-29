// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppL10nEs extends AppL10n {
  AppL10nEs([String locale = 'es']) : super(locale);

  @override
  String get homeGreetingMorning => 'Buenos días';

  @override
  String get homeGreetingAfternoon => 'Buenas tardes';

  @override
  String get homeGreetingEvening => 'Buenas noches';

  @override
  String get homeNearbySectionTitle => 'Cerca de ti';

  @override
  String get homeTopRestaurantsTitle => 'Mejor valorados';

  @override
  String get homeSeeAll => 'Ver todos';

  @override
  String get tabExplora => 'Explora';

  @override
  String get tabListas => 'Listas';

  @override
  String get tabMapa => 'Mapa';

  @override
  String get tabVisitas => 'Visitas';

  @override
  String get tabPerfil => 'Perfil';

  @override
  String get loginWithGoogle => 'Continuar con Google';

  @override
  String get loginWithApple => 'Continuar con Apple';

  @override
  String get loginPrivacyNotice =>
      'Al continuar, aceptas los Términos de uso y la Política de privacidad.';

  @override
  String get settingsTitle => 'Perfil';

  @override
  String get settingsLogOut => 'Cerrar sesión';

  @override
  String get settingsDeleteAccount => 'Eliminar cuenta';

  @override
  String get settingsMyData => 'Mis datos';

  @override
  String profileVisitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visitas',
      one: '1 visita',
      zero: 'Sin visitas',
    );
    return '$_temp0';
  }

  @override
  String mapRestaurantsNearby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count restaurantes cerca',
      one: '1 restaurante cerca',
      zero: 'Sin restaurantes',
    );
    return '$_temp0';
  }

  @override
  String get listsScreenTitle => 'Listas';

  @override
  String get listsEmpty => 'No hay listas en esta isla';

  @override
  String get visitsScreenTitle => 'Mis visitas';

  @override
  String get visitsEmpty => 'Aún no has visitado ningún restaurante';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonLoading => 'Cargando';

  @override
  String get commonError => 'Error';

  @override
  String get openStatusOpen => 'Abierto';

  @override
  String get openStatusClosed => 'Cerrado';
}
