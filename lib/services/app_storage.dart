import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// La única puerta al secure storage de la app (sesión, onboarding,
/// preferencias, cachés). Solo la identidad de la encuesta tiene su propio
/// almacén (`KeychainLocalIdSource`, servicio de Keychain propio en iOS).
///
/// En Android va con `encryptedSharedPreferences`. Con `flutter_secure_storage`
/// 9.x **no se pueden mezclar** dos configuraciones sobre el mismo almacén:
/// cada acceso cifrado mueve al almacén cifrado todas las claves del almacén
/// por defecto y las borra de él, así que quien leía con la configuración por
/// defecto (onboarding, `userId`, tokens…) dejaba de encontrarlas tras el
/// primer acceso cifrado del arranque. Por eso todo pasa por [instance].
///
/// En iOS las opciones de Android no cuentan: es el mismo Keychain de
/// siempre.
class AppStorage {
  AppStorage._();

  static const AndroidOptions androidOptions =
      AndroidOptions(encryptedSharedPreferences: true);

  static const FlutterSecureStorage instance =
      FlutterSecureStorage(aOptions: androidOptions);

  /// El almacén por defecto del plugin (hasta la 4.6.0 parte de los datos se
  /// escribía ahí). Solo para migrar y para limpiar.
  static const FlutterSecureStorage legacy = FlutterSecureStorage();

  /// Al arrancar, ANTES de cualquier lectura: pasa al almacén cifrado lo que
  /// quede en el almacén por defecto y no exista ya en el cifrado (quien
  /// venga de la 4.5.4 no pierde sesión ni ajustes) y lo borra del antiguo.
  /// Solo Android; en iOS no hay nada que mover. Nunca bloquea el arranque.
  static Future<void> migrateLegacy({
    @visibleForTesting bool? android,
    @visibleForTesting FlutterSecureStorage from = legacy,
    @visibleForTesting FlutterSecureStorage to = instance,
  }) async {
    if (!(android ?? Platform.isAndroid)) return;
    try {
      final old = await from.readAll();
      if (old.isEmpty) return;
      for (final e in old.entries) {
        if (await to.read(key: e.key) == null) {
          await to.write(key: e.key, value: e.value);
        }
      }
      for (final k in old.keys) {
        await from.delete(key: k);
      }
    } catch (e) {
      // Sin esta copia el plugin aún mueve las claves al primer acceso
      // cifrado; nunca se bloquea el arranque.
      debugPrint('AppStorage.migrateLegacy: ${e.runtimeType}');
    }
  }
}
