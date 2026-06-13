import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/services/app_storage.dart';
import 'package:path_provider/path_provider.dart';

/// En **iOS** el Keychain (donde vive `flutter_secure_storage`) NO se borra al
/// desinstalar la app. Resultado: tras reinstalar (TestFlight, App Store) quedan
/// flags viejos —`onBoardingFinished`, tokens de sesión, preferencias— y el
/// onboarding no vuelve a salir, además de aparecer "logueado" con tokens
/// muertos.
///
/// Detectamos el **primer arranque tras una instalación** con un fichero
/// marcador en el sandbox de la app (Application Support), que SÍ se elimina al
/// desinstalar. Si el marcador no existe, limpiamos el secure storage para
/// arrancar en limpio y lo creamos.
class FreshInstallGuard {
  static const _markerName = '.dcc_installed_v1';

  /// Debe llamarse en `main()` ANTES de `runApp` (antes de hidratar el
  /// onboarding y de leer tokens). Es idempotente y no bloquea el arranque ante
  /// errores.
  static Future<void> ensure() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final marker = File('${dir.path}/$_markerName');
      if (await marker.exists()) return; // ya inicializado en esta instalación

      // Primer arranque de esta instalación: borra cualquier resto del Keychain
      // que sobreviviera a una desinstalación previa. Limpiamos ambos stores
      // (el por defecto y el de AppStorage con opciones Android) por si acaso.
      await const FlutterSecureStorage().deleteAll();
      await AppStorage.instance.deleteAll();

      await dir.create(recursive: true);
      await marker.create();
    } catch (_) {
      // Si algo falla no bloqueamos el arranque: en el peor caso el onboarding
      // se comporta como hasta ahora.
    }
  }
}
