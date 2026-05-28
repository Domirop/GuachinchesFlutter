Añadir **Firebase Remote Config** (para feature flags y kill-switches) y **Firebase Cloud Messaging (FCM)** (para push notifications). Fase 2 — asume que `06a-crashlytics-logger.md` ya está mergeado (AppLogger existe).

CONTEXTO ACTUAL (verificado):

- `firebase_core`, `firebase_analytics`, `firebase_crashlytics` (tras 06a) presentes en pubspec.
- `firebase_remote_config` y `firebase_messaging` NO añadidos.
- En `lib/ui/pages/profile/notifications_page.dart` ya existe UI de "Notificaciones" pero NO está conectada a FCM real.
- iOS NO tiene Push Notifications capability en `ios/Runner/Runner.entitlements` (verificar).
- Android NO tiene `POST_NOTIFICATIONS` permission ni `default_notification_channel_id` meta-data en manifest.

CONTRATO FUNCIONAL:

1. **pubspec.yaml**: añadir
   ```yaml
   firebase_remote_config: ^4.3.8
   firebase_messaging: ^14.7.10
   ```

2. **iOS — `ios/Runner/Runner.entitlements`**: añadir capability Push Notifications:
   ```xml
   <key>aps-environment</key>
   <string>development</string>
   ```
   En `ios/Runner/Info.plist` añadir `UIBackgroundModes` con `remote-notification` y `fetch` si no están.

3. **Android — `android/app/src/main/AndroidManifest.xml`**: añadir dentro de `<manifest>`:
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
   ```
   Dentro de `<application>`:
   ```xml
   <meta-data
     android:name="com.google.firebase.messaging.default_notification_channel_id"
     android:value="dcc_default_channel" />
   ```

4. **Crear `lib/core/remote_config/dcc_remote_config.dart`**:
   ```dart
   class DccRemoteConfig {
     DccRemoteConfig._();
     static final instance = DccRemoteConfig._();
     final _rc = FirebaseRemoteConfig.instance;

     Future<void> init() async {
       await _rc.setConfigSettings(RemoteConfigSettings(
         fetchTimeout: const Duration(seconds: 10),
         minimumFetchInterval: const Duration(hours: 1),
       ));
       await _rc.setDefaults(const {
         'show_curated_lists': true,
         'show_weather_chip': true,
         'min_supported_build': 1,
         'maintenance_mode': false,
       });
       try {
         await _rc.fetchAndActivate();
       } catch (e, st) {
         AppLogger.warn('remote-config', 'fetch failed: $e');
       }
     }

     bool get showCuratedLists => _rc.getBool('show_curated_lists');
     bool get showWeatherChip => _rc.getBool('show_weather_chip');
     int get minSupportedBuild => _rc.getInt('min_supported_build');
     bool get maintenanceMode => _rc.getBool('maintenance_mode');
   }
   ```
   Inicializar en `main.dart` tras `Firebase.initializeApp()`: `await DccRemoteConfig.instance.init();`.

5. **Wiring de feature flags (mínimo necesario para demostrar el patrón)**:
   - `new_home_screen.dart`: envolver el `WeatherChip` en `if (DccRemoteConfig.instance.showWeatherChip)` para poder esconderlo via Remote Config sin release.
   - `listas_screen.dart`: envolver la sección de curated lists en `if (DccRemoteConfig.instance.showCuratedLists)`.
   - En `main.dart` o splash: si `maintenanceMode == true`, navegar a una pantalla `MaintenanceScreen` (`lib/ui/pages/maintenance/maintenance_screen.dart` nueva) con texto "Estamos haciendo mejoras, volvemos pronto."
   - Anchor `maintenance-screen-root` en la nueva pantalla.

6. **Crear `lib/core/push/push_notifications_service.dart`**:
   ```dart
   class PushNotificationsService {
     PushNotificationsService._();
     static final instance = PushNotificationsService._();
     final _fcm = FirebaseMessaging.instance;

     Future<void> init() async {
       final settings = await _fcm.requestPermission(
         alert: true, badge: true, sound: true,
       );
       if (settings.authorizationStatus != AuthorizationStatus.authorized) {
         AppLogger.info('push', 'permission denied or not determined');
         return;
       }
       final token = await _fcm.getToken();
       AppLogger.info('push', 'fcm token: $token');
       // TODO(backend): POST token to /v1/user/{id}/push-token (out of scope of this PR — see migration doc).

       FirebaseMessaging.onMessage.listen((msg) {
         AppLogger.info('push', 'foreground message: ${msg.notification?.title}');
       });
       FirebaseMessaging.onMessageOpenedApp.listen((msg) {
         AppLogger.info('push', 'opened from notif: ${msg.data}');
         // Routing: si data contiene 'restaurantId', navegar a detail. Out of scope hoy.
       });
     }
   }
   ```
   Llamar `await PushNotificationsService.instance.init();` desde `main.dart` solo TRAS el login (no en arranque frío — pedir permisos en arranque es mal UX). Buen sitio: tras `onLoggedIn` en el login presenter o tras `bootstrap()` del home si hay user.

7. **Cross-repo migration docs** (escribir a mano tras "sí" del usuario, el hook bloquea al generator):
   - `.claude/coordination/migration-backend/019-push-token-storage.md`:
     * Endpoint `POST /v1/user/{id}/push-token` body `{token: string, platform: 'ios'|'android'}` → upserta en `user_push_tokens` (userId, token único por device).
     * Endpoint `DELETE /v1/user/{id}/push-token/{token}` para logout.
   - `.claude/coordination/migration-backend/020-remote-config-keys.md`:
     * Lista de keys que la app espera en Remote Config console:
       `show_curated_lists` (bool, default true), `show_weather_chip` (bool, true), `min_supported_build` (int, 1), `maintenance_mode` (bool, false).

ANCHORS:
- `maintenance-screen-root`

TESTS OBLIGATORIOS:

- `test/core/dcc_remote_config_test.dart`:
  * Defaults se aplican si fetch falla (mock `_rc` con un fake o usa `FirebaseRemoteConfigMocks` si está disponible — si requiere paquete, escribir un wrapper inyectable: `DccRemoteConfig.test(FakeRC fake)`).
  * Getters devuelven los valores tras setDefaults.

- NO testear `PushNotificationsService` (requiere binding nativo y mock de iOS APNs es desproporcionado).

- `test/widget/maintenance_screen_test.dart`:
  * Renderiza el copy esperado y el anchor.

PROHIBIDO:
- Pedir permisos de push en arranque frío. Solo tras login.
- Hardcodear feature flags en código (lo que sí está cableado en este PR son los 2 ejemplos del paso 5; cualquier otro nuevo va por Remote Config).
- Implementar el push-token POST al backend (eso depende del doc cross-repo 019, otro sprint).
- Tragar errores de Remote Config (sí está OK logear y usar defaults).

OUT OF SCOPE:
- Push token sync con backend (depende del doc 019; cliente solo logea el token por ahora).
- Routing desde push (cuando llega notif con `restaurantId`, abrir detail — futuro PR).
- A/B testing con Remote Config (solo flags simples por ahora).
- iOS production APS environment (`development` está OK para staging; cambiar a `production` cuando se prepare release real).

ENTREGA: `flutter analyze` limpio, `flutter test test/core/dcc_remote_config_test.dart test/widget/maintenance_screen_test.dart` verde, build iOS y Android compilan (si el harness no puede compilar, basta con que el evaluator confirme que los ficheros de manifest están bien formados). Aviso en el resumen del generator: "Faltan crear `.claude/coordination/migration-backend/019-push-token-storage.md` y `020-remote-config-keys.md` — bloqueados por hook, pedir al usuario."
