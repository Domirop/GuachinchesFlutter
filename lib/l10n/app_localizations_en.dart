// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeNearbySectionTitle => 'Near you';

  @override
  String get homeTopRestaurantsTitle => 'Top rated';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get tabExplora => 'Explore';

  @override
  String get tabListas => 'Lists';

  @override
  String get tabMapa => 'Map';

  @override
  String get tabVisitas => 'Visits';

  @override
  String get tabPerfil => 'Profile';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get loginWithApple => 'Continue with Apple';

  @override
  String get loginPrivacyNotice =>
      'By continuing, you accept the Terms of Use and Privacy Policy.';

  @override
  String get settingsTitle => 'Profile';

  @override
  String get settingsLogOut => 'Sign out';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsMyData => 'My data';

  @override
  String profileVisitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visits',
      one: '1 visit',
      zero: 'No visits',
    );
    return '$_temp0';
  }

  @override
  String mapRestaurantsNearby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count restaurants nearby',
      one: '1 restaurant nearby',
      zero: 'No restaurants',
    );
    return '$_temp0';
  }

  @override
  String get listsScreenTitle => 'Lists';

  @override
  String get listsEmpty => 'No lists on this island';

  @override
  String get visitsScreenTitle => 'My visits';

  @override
  String get visitsEmpty => 'You haven\'t visited any restaurant yet';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonError => 'Error';

  @override
  String get openStatusOpen => 'Open';

  @override
  String get openStatusClosed => 'Closed';
}
