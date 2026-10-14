# Encuesta: un voto por negocio y móvil (parte cliente, plan App Check)

- **Diseño:** `guachinches-coordination/design/rediseno-ios27/ENCUESTA-SEGURIDAD.md`, sección «Plan elegido: App Check».
- **Migración móvil:** `guachinches-coordination/migration-mobile/012-encuesta-voto-dispositivo-atestado.md`.

El propietario descartó el plan completo (claves de DeviceCheck, cuenta de servicio de Play
Integrity y la beta de *device recall*). En su lugar se usa la identidad del móvil más
**Firebase App Check**, sin cuenta de usuario. Este documento explica qué hace la app, qué
protege y qué no, cómo probarlo y qué hay que configurar.

## 1. Qué hace la app

| Pieza | Dónde | Qué guarda o envía |
|---|---|---|
| Identidad iOS | `KeychainLocalIdSource` (`lib/services/survey_integrity/survey_integrity.dart`) | Un secreto aleatorio `L` de 32 bytes en el Keychain con `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, sin sincronizar y en un servicio propio (`com.jonay.guachinches.survey`) para que `FreshInstallGuard` no lo borre al reinstalar. Solo sale `localIdHash = SHA256("gm-survey-id:" ‖ L)`. |
| Identidad Android | `SsaidLocalIdSource` + `android/…/SurveyDevicePlugin.kt` | `localIdHash = SHA256("gm-survey-id:" + SSAID)`. El SSAID no sale del código nativo. |
| App Check | `FirebaseAppCheckTokenSource` | Proveedores: App Attest (iOS), Play Integrity (Android) y Debug en las compilaciones de depuración. Se activa la primera vez que se abre la encuesta, sin refresco en segundo plano. `votes` pide `getLimitedUseToken()` nuevo en cada envío; `my-votes`, el token estándar (`getToken()`, que el servidor no consume y no gasta cuota de Play Integrity). Va en la cabecera `X-Firebase-AppCheck`. El token se pide justo antes del POST. |
| `DeviceIdentityService` | `lib/services/survey_integrity/device_identity_service.dart` | Monta el cuerpo `{platform, localIdHash, votes?}` y pide el token de cada petición. Sin token, no hay petición. Guarda el *Future* de la identidad (no el resultado): dos llamadas a la vez en el primer arranque comparten la misma lectura y la misma creación del secreto. |
| *Certificate pinning* | `lib/services/survey_integrity/survey_pinning.dart` + `assets/certs/*.pem` | El cliente HTTP de `/surveys/v3` solo confía en ISRG Root X1 e ISRG Root X2 (`SecurityContext(withTrustedRoots: false)`). Ver §7. |
| Repositorio | `HttpRemoteRepository` | `GET /surveys/v3/editions/current`, `POST …/editions/:id/my-votes` y `POST …/editions/:id/votes`. Errores tipados (`SurveyApiException`, `SurveyNetworkException`). **No** registra ni el cuerpo, ni la respuesta, ni las cabeceras. |
| Presenter | `lib/ui/pages/survey_in_app/survey_vote_presenter.dart` | Estado de la vista (`SurveyVoteState`) y errores tipados (`SurveyFailure`). |

Con este cambio desaparecen `device_id_service.dart` (que en Android usaba la huella de
compilación), `DEVICE_HMAC_SECRET` de `env_files/*.env` y el HMAC que se calculaba en el
cliente. **El secreto antiguo sigue en el historial de git y en la imagen de Docker:
hay que rotarlo.** `SurveyInAppPresenter` pasa a ser un adaptador sobre el presenter
nuevo, para que `survey_in_app_page.dart` y `LegacyPremiosFlowController` sigan
compilando y usen el contrato v3. `splash_screen_presenter.checkVersion` ya compara bien
las versiones (antes, 5.0 frente a 4.7 pedía actualizar).

### Flujo

1. `GET editions/current`. Si la edición es `upcoming` o `closed`, el flujo se detiene. Si la versión de la app es menor que `minAppVersion`, aparece la pantalla de actualizar.
2. Activa App Check y lee la identidad. Si el móvil no puede dar token (no tiene App Attest, Google Play ni Play Integrity), la etapa es `unsupported`.
3. `POST my-votes` con el token estándar: devuelve lo que este móvil ya votó, o `blocked`.
4. Candidatos de la edición, sin los negocios ya votados (con `voteScope=business`, en cualquier categoría).
5. `POST votes` con un token de uso limitado nuevo, que el servidor consume.

### Reintentos

- Solo se reintenta con espera (0,6 s y 2 s) al leer la edición y los candidatos, que no llevan token.
- Un voto **nunca** se reenvía con el mismo token. Hay un único reintento automático, con un token recién pedido, cuando el servidor responde `403 integrity_failed` porque el token ya se usó (`app_check_replayed`) o porque tiene más de 120 s (`reason: app_check_invalid` con `details.cause: "stale"`). En los dos casos el voto no llegó a contarse.
- Un fallo de *pinning* (`SurveyInsecureConnection`) no se reintenta solo: esperar no lo arregla.
- Con `429`, `503 verification_unavailable` o un error de red no hay reintento automático: la vista muestra «Reintentar» (respetando `Retry-After`), y cada reintento pide un token nuevo. `503 integrity_unavailable` (backend sin configurar) no es reintentable.
- Modo avión a mitad del envío: si el `POST` salió y la conexión se cortó, la app recuerda esos votos. Si al reintentar el servidor responde `409` con todos ellos, significa que el primer envío sí entró, y la app muestra el éxito en lugar del error.

### Lo que nunca se registra

Ni `AppLogger` ni Crashlytics reciben tokens de App Check, `localIdHash`, el secreto ni
el SSAID. Solo se registran etapas, estados HTTP y códigos de error. Los modelos con
credenciales ocultan su contenido en `toString()`. Hay tests que lo comprueban en
`test/survey_v3/`.

## 2. Modelo de amenazas real (lo que queda abierto)

La garantía es la del servidor: `UNIQUE (edición, identidad, negocio)`. Con este plan,
la identidad es el **secreto del Keychain** en iOS y el **SSAID** en Android. App Check
garantiza que la petición viene de la app genuina en un dispositivo íntegro. Ni Apple
ni Google guardan bits que sobrevivan a un restablecimiento.

| Ataque | iPhone | Android |
|---|---|---|
| Reinstalar la app | **Parcial**: el Keychain `ThisDeviceOnly` sobrevive en la práctica, pero Apple no lo garantiza; si se pierde, es una identidad nueva | **Bloqueado**: el SSAID no cambia con la misma clave de firma |
| Borrar los datos de la app | n/a | **Bloqueado** |
| Otra cuenta en la app o cerrar sesión | **Bloqueado** | **Bloqueado** |
| Script contra la API, app modificada o emulador | **Bloqueado** por App Check (App Attest) | **Bloqueado** por App Check (Play Integrity) |
| Repetir una petición capturada | **Bloqueado**: el token es de un solo uso | **Bloqueado** |
| Cambiar de IP o la hora del móvil | **Bloqueado** (manda el servidor) | **Bloqueado** |
| **Restablecer de fábrica o borrar el iPhone** | **ABIERTO**: `L` nuevo, identidad nueva y vuelve a votar | **ABIERTO**: SSAID nuevo y vuelve a votar |
| **Otro usuario o perfil de trabajo de Android** | n/a | **ABIERTO**: cada perfil tiene su SSAID |
| **Otro móvil físico** | **ABIERTO** (fuera de cualquier garantía técnica) | **ABIERTO** |
| Restaurar una copia en otro iPhone | `L` no migra (`ThisDeviceOnly`): es otro móvil y vota | n/a |
| *Jailbreak* o *root* con ocultación | App Attest puede saltarse con el sistema modificado | Play Integrity a veces se supera con *keyboxes* filtrados |
| **Fabricar identidades con tokens auténticos** (§10.2 #11) | **Mitigado** por el *certificate pinning*: con una CA de usuario y un proxy ya no se pueden leer ni reescribir las peticiones de `/surveys/v3`. Queda abierto con *jailbreak* o Frida (desactivar el pinning en el propio proceso) | Igual (con *root*) |
| Tokens de depuración registrados en producción | Cualquiera con uno vota desde un emulador o un script: **hay que borrarlos antes de abrir la edición** | Igual |

## 3. Interfaz para la vista

```dart
final presenter = SurveyVotePresenter.platform(HttpRemoteRepository(Client()));
presenter.addListener(() => setState(() {}));   // es un ChangeNotifier
await presenter.load();

presenter.state.stage;       // SurveyVoteStage
presenter.state.failure;     // SurveyFailure? (sealed)
presenter.state.edition;     // SurveyEdition? (fechas, categorías, label)
presenter.state.candidates;  // Map<categoría, List<SurveyInAppChoice>>, sin los ya votados
presenter.state.selection;   // Map<categoría, value>
presenter.state.conflicts;   // List<SurveyVoteSelection> del último 409 (filas que hay que marcar)
presenter.state.voted;       // Map<categoría, Set<value>>
presenter.state.accepted;    // votos aceptados (stage == sent)
presenter.state.canSubmit / isConflict(cat, value) / isVoted(value)

presenter.select(cat, value);   // con null o con el mismo value, la quita
await presenter.submit();
await presenter.retry();        // recarga o reenvía según el estado (siempre con un token nuevo)
presenter.voteAgain();          // «Votar a otros sitios»
```

| `stage` | Pantalla |
|---|---|
| `loading` | Cargando |
| `ready` | Papeleta; mirar `failure` para el aviso |
| `submitting` | Botón bloqueado |
| `sent` | Gracias (`accepted`) |
| `upcoming` / `closed` | Votación aún no abierta o ya cerrada (`edition` trae las fechas) |
| `blocked` | «Este móvil no puede votar.» |
| `upgradeRequired` | Actualizar (`SurveyUpgradeRequired.minAppVersion`) |
| `unsupported` | «Este móvil no puede verificarse para votar» (sin App Attest o sin Google Play) |
| `failed` | No se pudo cargar. `failure` dice por qué y `retry()` vuelve a empezar. |

| `failure` (con `stage == ready` o `failed`) | Origen | Texto del diseño |
|---|---|---|
| `SurveyNoSelection` / `SurveyTooFast` | cliente | los de siempre |
| `SurveyAlreadyVoted(conflicts)` | 409 | «Ya has votado a este negocio anteriormente.» Las filas en conflicto ya están quitadas de `selection`. |
| `SurveyIntegrityFailed(code, reason)` | 403 `integrity_failed` (`app_check_missing` / `invalid` / `replayed` / `app_unrecognized`), o App Check rechazado en el móvil (`code == 'client'`) | «No hemos podido verificar este móvil. Actualiza la app desde la App Store / Google Play.» |
| `SurveyRateLimited(retryAfter)` | 429, o Firebase limitando tokens | «Demasiados intentos, prueba en un minuto.» |
| `SurveyVerificationUnavailable(retryAfter)` | `503 verification_unavailable` (Firebase o su JWKS caídos; respetar `Retry-After`), o Firebase, Apple o Google sin servicio al pedir el token | «No podemos verificar ahora mismo, inténtalo en unos minutos.» (reintentable) |
| `SurveyVotingUnavailable` | `503 integrity_unavailable` (backend de la encuesta sin configurar) | propuesto: «La votación no está disponible ahora mismo. Vuelve más tarde.» (**no** reintentable) |
| `SurveyNetworkFailure` | red (también al pedir el token) | «Se nos fue la cobertura» |
| `SurveyInsecureConnection` | la cadena TLS no acaba en las raíces fijadas (proxy, CA instalada, wifi con portal cautivo) | propuesto: «No podemos conectar de forma segura. Prueba con otra red (datos móviles).» |
| `SurveyServerFailure(status, code)` | 400, `413 payload_too_large`, 5xx, respuesta inesperada | genérico |
| `SurveyInvalidOption(option)` | 422 | genérico |

`failure.retryable` indica si el botón principal pasa a ser «Reintentar».

## 4. Configuración mínima en la consola de Firebase

1. **App Check → Apps → iOS (`com.jonay.guachinches`) → App Attest.** Hay que indicar el **Team ID** (`GQ54L72VZ8`); no hace falta la clave `.p8`. Sin respaldo DeviceCheck: la app exige iOS 15 y todos esos iPhone tienen App Attest, y DeviceCheck pediría la `.p8`. En el portal de Apple, activar la capacidad **App Attest** en el App ID y regenerar los perfiles. **Sin esto falla la firma de Release**, porque `RunnerRelease.entitlements` declara `com.apple.developer.devicecheck.appattest-environment = production`. Debug y Profile usan `development`.
2. **App Check → Apps → Android → Play Integrity.** Pegar la huella **SHA‑256 del certificado de firma de Play** (Play Console → *Integridad de la app* → *Firma de apps*). Vincular el proyecto de Cloud de Firebase en Play Console (*Play Integrity API*).
3. **Compilaciones de depuración.** Lo recomendable es registrarlas en Firebase como **otra app** (otro `appId`, p. ej. `com.jonay.guachinches.debug`), que el backend **no** acepta en producción. Hoy debug y release comparten bundle id y `appId`; si no se separan, como mínimo hay que **borrar los tokens de depuración antes de abrir la edición** (punto 5): con uno, cualquiera vota desde un emulador o un script. Tokens de depuración (*App Check → Apps → ⋮ → Administrar tokens de depuración*). Al arrancar una compilación de depuración y abrir la encuesta:
   - iOS: el token aparece en la consola de Xcode (`Firebase App Check Debug Token: …`).
   - Android: el token aparece en logcat (`DebugAppCheckProvider: Enter this debug secret…`).
   
   Cada simulador, emulador o instalación de depuración necesita el suyo. No los subas al repo.
4. **No actives el «enforcement»** de App Check para otros servicios de Firebase (Remote Config, Messaging…). La encuesta valida el token en el backend; activar el enforcement en esos servicios podría romper a usuarios con versiones antiguas. Comprueba que está habilitada la **Firebase App Check API** en Google Cloud.
5. **Borra los tokens de depuración** del proyecto antes de abrir la edición.
6. **Backend:** el `appId` de Firebase de cada plataforma y la credencial de *firebase-admin* (rol «Firebase App Check Token Verifier»). Lo configura el backend.
7. **Antes de abrir la edición:** subir la versión mínima de `/version` y rotar `DEVICE_HMAC_SECRET`.
8. **Durante una edición no se toca la identidad de la app:** ni rotar la clave de firma de Play (cambia el SSAID de todos los Android y la huella SHA‑256 que valida Play Integrity: todos los móviles serían identidades nuevas o no podrían votar) ni cambiar de Team de Apple (cambia el App ID de App Attest y el acceso al Keychain: identidades nuevas en iOS).

Para desarrollar contra el backend en modo `fake`, ejecuta `flutter run --dart-define=SURVEY_INTEGRITY=fake`. Solo funciona en debug, y el backend local debe arrancar con `NODE_ENV=development`. La app envía `fake-appcheck.<appId>.<uuid>~<iat>` (con `iat` en segundos), el formato de `fakeAppCheck.verifier.ts`; así también se prueba la frescura.

## 5. Cómo probar en dispositivos reales

- **iPhone:** compilación *Debug* desde Xcode en un iPhone real, con el token de depuración registrado (proveedor Debug), o *Profile/Release* para probar App Attest de verdad (TestFlight usa siempre producción). En el simulador, App Attest no existe: en Release el resultado es `unsupported`, sin cierres. En Debug usa el proveedor Debug.
- **Android:** *internal testing track* instalado desde Play (Play Integrity reconoce el certificado de Play). En el emulador, solo con el proveedor Debug.

### Lista manual de ataques

Para cada caso, vota primero el negocio A (`201`) y luego intenta votarlo otra vez.

| # | Ataque | iPhone: resultado esperado | Android: resultado esperado |
|---|---|---|---|
| 1 | Desinstalar y reinstalar | A aparece como votado (`my-votes`). Forzar el envío → `409`. **Verifica que el Keychain sobrevive.** | El mismo SSAID → `409` |
| 2 | Borrar los datos de la app | n/a | `409` |
| 3 | Restablecer de fábrica o borrar el iPhone | **Vuelve a votar** (riesgo aceptado: anótalo) | **Vuelve a votar** (riesgo aceptado) |
| 4 | Otro usuario o perfil de Android | n/a | **Vuelve a votar** (riesgo aceptado) |
| 5 | Otra cuenta en la app o cerrar sesión | `409` | `409` |
| 6 | Modo avión justo después de pulsar Enviar | Aviso de red. Al reintentar: si entró, «Gracias» (no un `409`); si no, `201`. Nunca dos votos. | Igual |
| 7 | Modo avión antes de abrir la encuesta | Aviso de red; «Reintentar» carga bien | Igual |
| 8 | Cambiar la hora del móvil | Sin efecto | Sin efecto |
| 9 | Pulsar Enviar dos veces rápido | Un solo `POST` (`submitting`); si hubiera dos, el `UNIQUE` deja uno | Igual |
| 10 | Repetir con un proxy la petición capturada | `403 integrity_failed / app_check_replayed` | Igual |
| 11 | Llamar a la API con `curl` sin token o con uno inventado | `403 app_check_missing / app_check_invalid` | Igual |
| 12 | Simulador o emulador en Release | `unsupported` («no puede verificarse»), sin cierres | `unsupported` o `403` |
| 13 | **Proxy con CA de usuario** (Charles, mitmproxy o Proxyman) con la CA instalada y de confianza en *Ajustes → General → Información → Certificados* y el proxy en la wifi | Con el pinning activo, el proxy **no puede leer ni reescribir** `/surveys/v3/*`: el handshake falla y la app muestra `SurveyInsecureConnection`. En el proxy solo se ve el `CONNECT` y un TLS abortado. El resto de la app (fuera de la encuesta) sí pasa por el proxy, y eso es lo esperado. | Desde Android 7 las CA de usuario no se aceptan por defecto, pero el pinning lo cubre igual (también con *root* y la CA en el almacén del sistema). |
| 14 | Mismo proxy en modo «pass-through» o sin interceptar `api.guachinchesmodernos.com` | La encuesta funciona con normalidad | Igual |

## 6. Qué no se puede probar sin dispositivos reales o sin claves

- App Attest real: necesita un iPhone físico, la capacidad activada y el Team ID en Firebase.
- Play Integrity real: necesita la app instalada desde Play y la huella SHA‑256 en Firebase.
- La persistencia del Keychain al desinstalar: Apple no la garantiza. Se verifica a mano (caso 1).
- La verificación y el consumo del token en el servidor: necesita *firebase-admin* con credenciales. Sin ellas, el backend en modo `fake`.

## 7. *Certificate pinning*: raíces y rotación

`api.guachinchesmodernos.com:459` usa Let's Encrypt. Cadena del 14/10/2026 (`openssl s_client -showcerts`):
hoja (caduca el 12/12/2026) ← **YR2** (intermedia, caduca el 2/9/2028) ← **Root YR**, con firma cruzada de **ISRG Root X1** (la firma cruzada caduca el 2/9/2032).

Raíces fijadas (`assets/certs/`, sacadas del almacén de raíces de macOS):

| Fichero | Raíz | Tipo | Caduca | SHA‑256 (DER) |
|---|---|---|---|---|
| `isrg_root_x1.pem` | ISRG Root X1 | RSA 4096 | 4/6/2035 | `96:BC:EC:06:26:49:76:F3:74:60:77:9A:CF:28:C5:A7:CF:E8:A3:C0:AA:E1:1A:8F:FC:EE:05:C0:BD:DF:08:C6` |
| `isrg_root_x2.pem` | ISRG Root X2 (respaldo ECDSA) | ECDSA P‑384 | 17/9/2040 | `69:72:9B:8E:15:A8:6E:FC:17:7A:57:AF:B7:17:1D:FC:64:AD:D2:8C:2F:CA:8C:F1:50:7E:34:45:3C:CB:14:70` |

Se fijan **raíces**, no la hoja ni la intermedia: las renovaciones de cada 90 días y los cambios de intermedia (YR1, YR2, E7…) no rompen nada.
Comprobado contra el servidor real con `dart:io`: X1+X2 → handshake correcto; solo X2 → `HandshakeException`.
Un test (`device_identity_service_test.dart`) verifica las huellas para que nadie cambie las raíces por error.

**Riesgos y cómo rotar:**
- **Nueva generación de Let's Encrypt (Root YR / Root YE).** Hoy la cadena llega a X1 por la firma cruzada. Si el servidor deja de enviar la firma cruzada (o Let's Encrypt la retira), la cadena acabará en **Root YR autofirmada**, que no está fijada, y la encuesta fallará con `SurveyInsecureConnection`. **Antes de que pase:** añadir `isrg_root_yr.pem` (y `isrg_root_ye.pem` para ECDSA), sacados de <https://letsencrypt.org/certificates/> y comprobados por huella, a `assets/certs/` y a `SurveyPinning.roots`, y publicar esa versión **con margen** (los móviles tardan semanas en actualizarse). Después, subir `minAppVersion`.
- **Cambiar de CA en el balanceador** (p. ej. a ZeroSSL, Google Trust Services o un certificado de Cloudflare) **rompe la encuesta en todas las apps publicadas** hasta que actualicen. Procedimiento: 1) añadir la raíz nueva junto a las actuales; 2) publicar y esperar adopción; 3) subir `minAppVersion`; 4) solo entonces cambiar el certificado. Nunca durante una edición abierta.
- **Proxy corporativo o portal cautivo:** esos usuarios ven `SurveyInsecureConnection` y tienen que cambiar de red. Es el precio del pinning.
- **Desactivación:** solo en `kDebugMode` y solo con `--dart-define=SURVEY_INTEGRITY=fake` o contra un backend local (`localhost`, `10.0.2.2`, IPs privadas, `*.local`). En release el pinning está siempre activo.
- Solo cubre `/surveys/v3/*` (`editions/current`, `my-votes`, `votes`). Los candidatos (`category-restaurants/surveyjs/…`) y el resto de la app usan el cliente general.
