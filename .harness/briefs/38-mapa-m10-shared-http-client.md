Pantalla **Mapa** (`lib/ui/pages/map/map_search.dart`). Sprint **M10 (de la serie M1…M13, uno por harness)**: **reutilizar el http client compartido** en vez de crear un `Client()` nuevo por montaje. Hoy `MapSearchState.initState` hace `remoteRepository = HttpRemoteRepository(Client())`, abriendo su propio pool de conexiones cada vez que se monta el tab Mapa. Ya existe `sharedHttpClient` (un `IOClient` de vida-aplicación con keep-alive + `idleTimeout` de 5s) en `lib/data/http_client.dart`, ya usado por `visit_screen.dart`, `curated_list_detail_screen.dart` y `restaurant_detail_screen.dart`. M10 = **alinear el mapa con ese patrón**. Cliente-puro, cambio mínimo. Verificación por **code-review + `flutter analyze`** + suite existente sin nuevos fallos. **NO tests de widget** que monten `MapSearch`.

Ficheros a tocar: **sólo** `lib/ui/pages/map/map_search.dart`.

---

CONTEXTO (verificado leyendo el código):

- `lib/data/http_client.dart` exporta `final Client sharedHttpClient = IOClient(HttpClient()..idleTimeout = const Duration(seconds: 5));`. Comentario del fichero: reutilizar un único `Client` agrupa conexiones (keep-alive) evitando churn de abrir/cerrar pool por montaje; `idleTimeout` 5s evita reusar conexiones rancias entre navegaciones. No se cierra: vive lo que vive la app.
- En `map_search.dart`, **sólo dos** referencias a `http`:
  - Línea **27**: `import 'package:http/http.dart';` (sólo aporta el símbolo `Client`).
  - Línea **113** (en `initState`): `remoteRepository = HttpRemoteRepository(Client());`.
- Tras cambiar a `sharedHttpClient`, el import `package:http/http.dart` queda **sin usar** → hay que sustituirlo por `import 'package:guachinches/data/http_client.dart';` (que reexporta `Client` vía `package:http/http.dart`, así que el tipo `Client` sigue resuelto si hiciera falta, pero ya no se construye uno nuevo).
- `HttpRemoteRepository` acepta cualquier `Client` en su constructor (mismo patrón que el resto de pantallas migradas).

---

CONTRATO FUNCIONAL (sólo M10):

1. En `initState` (~línea 113), cambiar:
   ```dart
   remoteRepository = HttpRemoteRepository(Client());
   ```
   por:
   ```dart
   remoteRepository = HttpRemoteRepository(sharedHttpClient);
   ```
2. Ajustar imports: eliminar `import 'package:http/http.dart';` (línea 27, queda sin uso) y añadir `import 'package:guachinches/data/http_client.dart';`. Mantener el orden de imports razonable; `flutter analyze` no debe quejarse de import sin usar.
   - Comportamiento idéntico al actual (mismas llamadas API), sólo que comparten el pool de conexiones de la app.

---

NO MODIFICAR / NO ROMPER:
- `MapSearchPresenter`, `RestaurantMapCubit`, `RemoteRepository`, `HttpRemoteRepository` — NO cambiar firmas.
- `lib/data/http_client.dart` — NO tocar (ya existe y está bien).
- Las otras pantallas que aún usan `Client()` propio (`home.dart`, `listas_screen.dart`, etc.) — FUERA de alcance de M10 (cada una sería su propio cambio; M10 es sólo el mapa).
- `search_text.dart` (otro fichero del directorio map que también usa `Client()`) — FUERA de alcance (M10 toca SÓLO `map_search.dart`).
- M1-M9 — intactos. La lógica de markers, carrusel, drive strip, FABs, header/scrim, padding, empty-state, distance pill.
- El modelo, backend, presenter. `pubspec.yaml`, `ios/`, `android/`, `main.dart`.
- M10 **NO** toca: filtrado cliente (M11), pausa sensores (M12), marker n/d (M13).

PROHIBIDO (rechazo automático del Evaluator):
- Dejar `Client()` en `map_search.dart` (debe usar `sharedHttpClient`).
- Dejar el import `package:http/http.dart` sin usar (warning de analyze).
- Tocar `lib/data/http_client.dart`, otras pantallas, otros M's. Tests de widget que monten `MapSearch`. Tocar `pubspec.yaml`/`ios/`/`android/`/`main.dart`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze lib/ui/pages/map/map_search.dart`: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`). En particular, NINGÚN warning `unused_import`.
- Confirmar por diff: `HttpRemoteRepository(sharedHttpClient)` en initState; import de `http_client.dart` añadido; import de `package:http/http.dart` eliminado.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente; NO son regresiones.

OUT OF SCOPE (mencionar en informe):
- Migrar el resto de pantallas con `Client()` propio (`home.dart`, `listas_screen.dart`, `details.dart`, `search_text.dart`, etc.) a `sharedHttpClient`: follow-up de barrido global, fuera del cliente-puro de un solo fichero.

ENTREGA:
1. Diff de `map_search.dart` (sharedHttpClient + imports).
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando M10.

Diff objetivo ≤ 6 líneas.
