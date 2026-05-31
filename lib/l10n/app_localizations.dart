import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @homeGreetingMorning.
  ///
  /// In es, this message translates to:
  /// **'Buenos días'**
  String get homeGreetingMorning;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes'**
  String get homeGreetingAfternoon;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches'**
  String get homeGreetingEvening;

  /// No description provided for @homeNearbySectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Cerca de ti'**
  String get homeNearbySectionTitle;

  /// No description provided for @homeTopRestaurantsTitle.
  ///
  /// In es, this message translates to:
  /// **'Mejor valorados'**
  String get homeTopRestaurantsTitle;

  /// No description provided for @homeSeeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get homeSeeAll;

  /// No description provided for @tabExplora.
  ///
  /// In es, this message translates to:
  /// **'Explora'**
  String get tabExplora;

  /// No description provided for @tabListas.
  ///
  /// In es, this message translates to:
  /// **'Listas'**
  String get tabListas;

  /// No description provided for @tabMapa.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get tabMapa;

  /// No description provided for @tabVisitas.
  ///
  /// In es, this message translates to:
  /// **'Visitas'**
  String get tabVisitas;

  /// No description provided for @tabPerfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get tabPerfil;

  /// No description provided for @loginWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get loginWithGoogle;

  /// No description provided for @loginWithApple.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get loginWithApple;

  /// No description provided for @loginPrivacyNotice.
  ///
  /// In es, this message translates to:
  /// **'Al continuar, aceptas los Términos de uso y la Política de privacidad.'**
  String get loginPrivacyNotice;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get settingsTitle;

  /// No description provided for @settingsLogOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsLogOut;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsMyData.
  ///
  /// In es, this message translates to:
  /// **'Mis datos'**
  String get settingsMyData;

  /// No description provided for @profileVisitsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin visitas} =1{1 visita} other{{count} visitas}}'**
  String profileVisitsCount(int count);

  /// No description provided for @mapRestaurantsNearby.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin restaurantes} =1{1 restaurante cerca} other{{count} restaurantes cerca}}'**
  String mapRestaurantsNearby(int count);

  /// No description provided for @listsScreenTitle.
  ///
  /// In es, this message translates to:
  /// **'Listas'**
  String get listsScreenTitle;

  /// No description provided for @listsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay listas en esta isla'**
  String get listsEmpty;

  /// No description provided for @visitsScreenTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis visitas'**
  String get visitsScreenTitle;

  /// No description provided for @visitsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no has visitado ningún restaurante'**
  String get visitsEmpty;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @commonLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @openStatusOpen.
  ///
  /// In es, this message translates to:
  /// **'Abierto'**
  String get openStatusOpen;

  /// No description provided for @openStatusClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrado'**
  String get openStatusClosed;

  /// No description provided for @mapEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin restaurantes'**
  String get mapEmptyTitle;

  /// No description provided for @mapEmptyWithFilters.
  ///
  /// In es, this message translates to:
  /// **'No encontramos sitios con estos filtros. Prueba a quitarlos o cambiar de isla.'**
  String get mapEmptyWithFilters;

  /// No description provided for @mapEmptyNoFilters.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay restaurantes en esta isla.'**
  String get mapEmptyNoFilters;

  /// No description provided for @mapClearFilters.
  ///
  /// In es, this message translates to:
  /// **'Quitar filtros'**
  String get mapClearFilters;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'es':
      return AppL10nEs();
  }

  throw FlutterError(
      'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
