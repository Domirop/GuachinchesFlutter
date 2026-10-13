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
| App Check | `FirebaseAppCheckTokenSource` | Proveedores: App Attest (iOS), Play Integrity (Android) y Debug en las compilaciones de depuración. Se activa la primera vez que se abre la encuesta, sin refresco en segundo plano. Cada petición pide `getLimitedUseToken()` y lo envía en la cabecera `X-Firebase-AppCheck`. |
| `DeviceIdentityService` | `lib/services/survey_integrity/device_identity_service.dart` | Monta el cuerpo `{platform, localIdHash, votes?}` y pide un token nuevo para cada petición. Sin token, no hay petición. |
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
3. `POST my-votes` con un token nuevo: devuelve lo que este móvil ya votó, o `blocked`.
4. Candidatos de la edición, sin los negocios ya votados (con `voteScope=business`, en cualquier categoría).
5. `POST votes` con otro token nuevo, que el servidor consume.

### Reintentos

- Solo se reintenta con espera (0,6 s y 2 s) al leer la edición y los candidatos, que no llevan token.
- Un voto **nunca** se reenvía con el mismo token. Hay un único reintento automático, con un token nuevo, cuando el servidor responde `403 integrity_failed / app_check_replayed`. En ese caso el voto no llegó a contarse.
- Con `429`, `503` o un error de red no hay reintento automático: la vista muestra «Reintentar», y cada reintento pide un token nuevo.
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
| **Fabricar identidades con tokens auténticos** (§10.2 #11) | **Parcial**: el token no está ligado a la identidad. Con un proxy y una CA instalada, alguien puede quedarse tokens sin consumir y emparejarlos con `localIdHash` inventados. Lo frenan los límites del servidor; lo **cierra** el *certificate pinning* en la app, que no forma parte de este cambio | Igual |
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
| `SurveyVerificationUnavailable(retryAfter)` | 503, o Firebase, Apple o Google sin servicio | «No podemos verificar ahora mismo, inténtalo en unos minutos.» |
| `SurveyNetworkFailure` | red (también al pedir el token) | «Se nos fue la cobertura» |
| `SurveyServerFailure(status, code)` | 400, 5xx, respuesta inesperada | genérico |
| `SurveyInvalidOption(option)` | 422 | genérico |

`failure.retryable` indica si el botón principal pasa a ser «Reintentar».

## 4. Configuración mínima en la consola de Firebase

1. **App Check → Apps → iOS (`com.jonay.guachinches`) → App Attest.** Hay que indicar el **Team ID** (`GQ54L72VZ8`); no hace falta la clave `.p8`. Sin respaldo DeviceCheck: la app exige iOS 15 y todos esos iPhone tienen App Attest, y DeviceCheck pediría la `.p8`. En el portal de Apple, activar la capacidad **App Attest** en el App ID y regenerar los perfiles. **Sin esto falla la firma de Release**, porque `RunnerRelease.entitlements` declara `com.apple.developer.devicecheck.appattest-environment = production`. Debug y Profile usan `development`.
2. **App Check → Apps → Android → Play Integrity.** Pegar la huella **SHA‑256 del certificado de firma de Play** (Play Console → *Integridad de la app* → *Firma de apps*). Vincular el proyecto de Cloud de Firebase en Play Console (*Play Integrity API*).
3. **Tokens de depuración** (*App Check → Apps → ⋮ → Administrar tokens de depuración*). Al arrancar una compilación de depuración y abrir la encuesta:
   - iOS: el token aparece en la consola de Xcode (`Firebase App Check Debug Token: …`).
   - Android: el token aparece en logcat (`DebugAppCheckProvider: Enter this debug secret…`).
   
   Cada simulador, emulador o instalación de depuración necesita el suyo. No los subas al repo.
4. **No actives el «enforcement»** de App Check para otros servicios de Firebase (Remote Config, Messaging…). La encuesta valida el token en el backend; activar el enforcement en esos servicios podría romper a usuarios con versiones antiguas. Comprueba que está habilitada la **Firebase App Check API** en Google Cloud.
5. **Borra los tokens de depuración** del proyecto antes de abrir la edición.
6. **Backend:** el `appId` de Firebase de cada plataforma y la credencial de *firebase-admin* (rol «Firebase App Check Token Verifier»). Lo configura el backend.
7. **Antes de abrir la edición:** subir la versión mínima de `/version` y rotar `DEVICE_HMAC_SECRET`.

Para desarrollar contra el backend en modo `fake`, ejecuta `flutter run --dart-define=SURVEY_INTEGRITY=fake`. Solo funciona en debug: la app envía `fake-appcheck.<appId>.<uuid>`, que es el formato de `fakeAppCheck.verifier.ts`.

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

## 6. Qué no se puede probar sin dispositivos reales o sin claves

- App Attest real: necesita un iPhone físico, la capacidad activada y el Team ID en Firebase.
- Play Integrity real: necesita la app instalada desde Play y la huella SHA‑256 en Firebase.
- La persistencia del Keychain al desinstalar: Apple no la garantiza. Se verifica a mano (caso 1).
- La verificación y el consumo del token en el servidor: necesita *firebase-admin* con credenciales. Sin ellas, el backend en modo `fake`.
