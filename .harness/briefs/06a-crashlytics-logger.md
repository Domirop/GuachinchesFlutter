Añadir **Firebase Crashlytics** + un wrapper de logging (`AppLogger`) y reemplazar los 88 `print()` dispersos por llamadas a éste. Fase 1 de las tareas Firebase; Remote Config + FCM van en `06b-remoteconfig-fcm.md`.

CONTEXTO ACTUAL (verificado):

- `lib/main.dart:48` ya hace `await Firebase.initializeApp();`.
- `pubspec.yaml` ya tiene `firebase_core: ^2.17.0` y `firebase_analytics: ^10.5.1`.
- `firebase_crashlytics` NO está añadido.
- `lib/` tiene **88 `print(...)` directos** repartidos. No existe `AppLogger`.
- El proyecto YA tiene Firebase configurado en iOS (`ios/Runner/GoogleService-Info.plist` existe — verificar) y Android (`android/app/google-services.json` existe — verificar).

CONTRATO FUNCIONAL:

1. **pubspec.yaml** (excepción justificada al "prohibido pubspec"): añadir
   ```yaml
   firebase_crashlytics: ^3.4.8   # compatible con firebase_core 2.17
   ```
   Esta es la ÚNICA dependencia nueva en esta fase.

2. **iOS y Android**: NO modificar. Crashlytics funciona out-of-the-box con `firebase_core` ya configurado en ambas plataformas si `GoogleService-Info.plist` / `google-services.json` están presentes. Si el evaluator detecta que faltan, abortar la tarea con mensaje claro — no añadirlos a ciegas.

3. **Crear `lib/core/logging/app_logger.dart`**:
   ```dart
   import 'package:flutter/foundation.dart';
   import 'package:firebase_crashlytics/firebase_crashlytics.dart';

   /// Single entry point for logging in the app.
   /// In debug: prints to console with a tag.
   /// In release: forwards to Crashlytics (breadcrumbs + non-fatal records).
   class AppLogger {
     AppLogger._();

     /// Informational log. Debug-only print; release-only Crashlytics breadcrumb.
     static void info(String tag, String message) {
       if (kDebugMode) {
         debugPrint('[i][$tag] $message');
       } else {
         FirebaseCrashlytics.instance.log('[i][$tag] $message');
       }
     }

     /// Warning log. Always recorded as breadcrumb in release.
     static void warn(String tag, String message) {
       if (kDebugMode) {
         debugPrint('[!][$tag] $message');
       } else {
         FirebaseCrashlytics.instance.log('[!][$tag] $message');
       }
     }

     /// Error log. In release records as non-fatal exception with stack.
     static void error(String tag, Object error, [StackTrace? stack]) {
       if (kDebugMode) {
         debugPrint('[x][$tag] $error');
         if (stack != null) debugPrint(stack.toString());
       } else {
         FirebaseCrashlytics.instance.recordError(
           error,
           stack,
           reason: tag,
           fatal: false,
         );
       }
     }
   }
   ```

4. **Inicialización en `lib/main.dart`** (justo después de `Firebase.initializeApp()`):
   ```dart
   // Crash on unhandled Flutter errors and report to Crashlytics in release.
   FlutterError.onError = (errorDetails) {
     if (kDebugMode) {
       FlutterError.presentError(errorDetails);
     } else {
       FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
     }
   };
   PlatformDispatcher.instance.onError = (error, stack) {
     if (kDebugMode) {
       debugPrint('Uncaught async error: $error\n$stack');
     } else {
       FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
     }
     return true;
   };
   await FirebaseCrashlytics.instance
       .setCrashlyticsCollectionEnabled(!kDebugMode);
   ```

5. **Reemplazar `print()` → `AppLogger`**:
   - Recorrer `lib/` y reemplazar **todos** los `print(...)` por `AppLogger.info`, `AppLogger.warn` o `AppLogger.error` según contexto:
     * `print('something happened')` → `AppLogger.info('module-tag', 'something happened')`
     * `print('failed: $e')` → `AppLogger.warn('module-tag', 'failed: $e')`
     * `print('error: $e\n$stack')` o catches → `AppLogger.error('module-tag', e, stack)`
   - El `tag` debe ser el nombre del fichero o cubit/screen (kebab-case), p.ej. `'restaurant-cubit'`, `'http-repo'`, `'login-screen'`.
   - **No tragar errores nuevos**: si encuentras `catch (_) { print('...'); }`, convertirlo a `catch (e, st) { AppLogger.error('tag', e, st); }`. Mantener el comportamiento posterior (rethrow vs swallow) igual que estaba — no introduces lógica nueva, solo cambias el sink del log.

6. **Tests obligatorios**:
   - `test/core/app_logger_test.dart`:
     * `AppLogger.info` en debug mode no throws.
     * `AppLogger.error` con stacktrace no throws.
     * **NO** testear el path de Crashlytics (requiere binding nativo); basta con verificar que las llamadas son safe en debug y que el tag aparece en el debug output (capturando `debugPrint` con `Zone`).
   - **NO** añadir tests para cada cubit migrado — el reemplazo print→AppLogger es mecánico y los tests de cubit existentes ya cubren el comportamiento.

ANCHORS: no aplica (sin UI nueva).

PROHIBIDO:
- Añadir paquetes que no sean `firebase_crashlytics`.
- Modificar `ios/Runner/Info.plist` o `android/app/build.gradle` (Crashlytics no lo necesita en esta versión).
- Dejar **ningún** `print(...)` en `lib/` tras el cambio (sí está OK dejarlos en `test/` y `integration_test/`).
- Cambiar la semántica de bloques try/catch (si tragaba el error antes, sigue tragándolo; ahora solo se logea).
- Tocar `firebase_analytics` (sigue funcionando como hasta ahora).

OUT OF SCOPE:
- Remote Config (eso es `06b-remoteconfig-fcm.md`).
- FCM / push notifications (idem).
- Migrar `print` en `test/`.
- Cambiar el nivel de logging por configuración (todo es debug=console, release=crashlytics; sin niveles configurables por ahora).
- Symbol upload / dSYM scripts (Crashlytics autocaptura suficiente sin esto para una primera versión).

ENTREGA: diff que pase `flutter analyze` (sin nuevos errores), `flutter test test/core/app_logger_test.dart` verde, y `grep -r "print(" lib/ --include="*.dart" | wc -l` debe devolver **0**. Resto de tests existentes verdes.
