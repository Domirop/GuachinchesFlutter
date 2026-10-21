import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/pages/login/login_presenter.dart';

/// QA multidispositivo (B2): en Android el `idToken` de Google debe salir con
/// una audiencia estable y conocida: el cliente web (`client_type` 3) de
/// `google-services.json`, pasado como `serverClientId`. iOS no cambia.
void main() {
  test('Android: serverClientId = cliente web de google-services.json', () {
    final json = jsonDecode(
            File('android/app/google-services.json').readAsStringSync())
        as Map<String, dynamic>;
    final webClients = [
      for (final c in json['client'] as List)
        for (final o in (c['oauth_client'] as List? ?? const []))
          if (o['client_type'] == 3) o['client_id'] as String,
    ];
    expect(webClients, contains(LoginPresenter.googleAndroidServerClientId));

    final android = LoginPresenter.googleSignInFor(iOS: false);
    expect(android.serverClientId, LoginPresenter.googleAndroidServerClientId);
    expect(android.clientId, isNull);
  });

  test('iOS: sigue con su cliente propio y sin serverClientId', () {
    final ios = LoginPresenter.googleSignInFor(iOS: true);
    expect(ios.clientId,
        '138481024291-hmgnpru6pf1v5mlk7cdlh39ac2srgthc.apps.googleusercontent.com');
    expect(ios.serverClientId, isNull);
  });
}
