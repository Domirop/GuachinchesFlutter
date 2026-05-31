Resolver el **grupo E (performance)** de la auditoría de las pantallas de detalle. Dos optimizaciones in-scope, puramente cliente, sin tocar backend: (E1) **caching de distancia** en `CercaAhoraScreen` y (E2) **reutilizar un `http.Client` compartido** en las pantallas de detalle en vez de crear uno nuevo por montaje. El tercer hallazgo (E3, N+1 de list-appearances) es **estructural del backend** y queda documentado/OUT OF SCOPE (ver abajo). Cambios de lógica de rendimiento sin efecto visual: se verifican por **code-review + `flutter analyze`** + suite existente verde (regla 5 de CLAUDE.md). **NO escribir tests de widget** que monten estas pantallas (mocking de repos/sqflite/http; rabbit hole). Sí se permite —opcional— un test puro-Dart del helper de distancia si sale gratis, pero no es obligatorio.

Ficheros: `lib/data/http_client.dart` (NUEVO), `lib/ui/pages/cerca_abiertos/cerca_ahora_screen.dart`, `lib/ui/pages/restaurant_detail/restaurant_detail_screen.dart`, `lib/ui/pages/visit/visit_screen.dart`, `lib/ui/pages/curated_list_detail/curated_list_detail_screen.dart`.

---

CONTEXTO ACTUAL (verificado leyendo el código):

**E1 — CercaAhora recalcula distancia O(n log n) veces.**
- `cerca_ahora_screen.dart` `_computeFiltered(all, loc)` (`:366-393`): el `where` calcula `Geolocator.distanceBetween(loc, r)` una vez por restaurante (OK), pero el `result.sort((a,b) => ...)` (`:379-392`) vuelve a llamar `distanceBetween` para `a` y para `b` en **cada comparación** → ~2·n·log(n) cálculos trig redundantes.
- Además, el builder de la lista (`_buildListOrEmpty`, ListView.separated `:341-356`) calcula `distanceBetween` **otra vez** por item visible para formatear `distStr`.
- Resultado: la distancia de cada restaurante se computa muchas veces por frame. `_computeFiltered` se llama dentro de un `BlocBuilder` (se reejecuta en cada rebuild).

**E2 — cada pantalla de detalle crea su propio `http.Client` por montaje y no lo cierra.**
- RestaurantDetail `:72`: `_repo = widget.repository ?? HttpRemoteRepository(http.Client());`
- Visit `:59`: `_repo = HttpRemoteRepository(Client());`
- CuratedList `:28`: `HttpRemoteRepository(http.Client())`.
- Cada `Client()` abre su propio pool de conexiones; al no reusarse entre pantallas ni cerrarse en `dispose`, hay churn de sockets/handshakes TLS. El paquete `http` recomienda **un único `Client` reutilizado** para múltiples requests al mismo servidor (keep-alive). Esto además beneficia los fan-outs (`_loadListAppearances`, `_enrichVisits`) al reusar conexiones.
- `HttpRemoteRepository` guarda `final Client _client` (`:44`) y NO lo cierra por su cuenta — compartir el client es seguro.

**E3 — N+1 en `_loadListAppearances` (RestaurantDetail `:113-137`): ESTRUCTURAL, no fixable en cliente.**
- Hace `getCuratedLists()` y luego `getCuratedListById(l.id)` para CADA lista, sólo para saber si `widget.id` aparece y en qué posición.
- El modelo resumen `CuratedList` (`lib/data/model/curated_list.dart:5-50`) **no incluye los IDs de miembros** (sólo `count`), así que la pertenencia obliga a pedir el detalle completo de cada lista. No hay endpoint "appearances by restaurant".
- Ya está (a) paralelizado (`Future.wait`), (b) mitigado por la caché stale-while-revalidate (#4) en repeticiones, y (c) tras E2 reutiliza conexión. La eliminación real exige backend → OUT OF SCOPE (ver abajo). **NO refactorizar `_loadListAppearances` ni `_enrichVisits` en este sprint.**

---

CONTRATO FUNCIONAL:

**1. E2 — `http.Client` compartido (NUEVO, canónico):**
- Crear `lib/data/http_client.dart`:
  ```dart
  import 'package:http/http.dart';

  /// Cliente HTTP compartido de vida-aplicación. Reutilizar un único [Client]
  /// agrupa conexiones (keep-alive) entre pantallas y dentro de los fan-outs
  /// de requests, evitando el churn de abrir/cerrar un pool por cada montaje.
  /// No se cierra: vive lo que vive la app (patrón recomendado del paquete http).
  final Client sharedHttpClient = Client();
  ```
- RestaurantDetail (`:72`): sustituir `HttpRemoteRepository(http.Client())` por `HttpRemoteRepository(sharedHttpClient)` (mantener `widget.repository ?? ...`; el inyectado de tests no se toca).
- Visit (`:59`): `HttpRemoteRepository(Client())` → `HttpRemoteRepository(sharedHttpClient)`.
- CuratedList (`:28`): `HttpRemoteRepository(http.Client())` → `HttpRemoteRepository(sharedHttpClient)`.
- Importar `package:guachinches/data/http_client.dart` donde haga falta. **NO** cerrar `sharedHttpClient` en ningún `dispose` (es app-lifetime; cerrarlo rompería otras pantallas). NO tocar `main.dart` (su `Client()` queda fuera de scope).

**2. E1 — calcular la distancia una sola vez por restaurante en CercaAhora:**
- En `_computeFiltered`, calcular la distancia de cada restaurante UNA vez y arrastrarla. Definir un pequeño tipo privado portador, p.ej. un record `({Restaurant restaurant, double distanceMeters})` o una clase privada `_RestaurantWithDistance`.
- Flujo: mapear `all` → pares `(r, dist)` calculando `Geolocator.distanceBetween` una vez; `where` por `dist <= _maxRadiusKm*1000` sobre el `dist` ya calculado; `sort` por el `dist` ya calculado (comparador sin recomputar trig).
- Cambiar la firma de `_computeFiltered` para devolver la lista de pares (o un tipo que incluya la distancia), y que `_buildListOrEmpty` use ese `distanceMeters` arrastrado para formatear `distStr` (`:349-351`) en lugar de volver a llamar `distanceBetween` en el builder.
- Mantener idéntico el comportamiento observable: mismo orden (ascendente por distancia), mismo filtrado por radio, mismo string de distancia (`<1000 ? 'N m' : 'N.N km'`), mismos anchors `cerca-ahora-*`, misma UI. Sólo cambia CUÁNTAS veces se computa la distancia.
- Conservar `AppColors.atlantico`, la tipografía `'SF Pro Display'`, los tokens `context.brand.*` (de sprint B) y la lógica de `RefreshIndicator`/empty/skeleton.

---

NO MODIFICAR:
- `pubspec.yaml`, `ios/`, `android/`. (`http` YA es dependencia; sólo se añade un fichero con un `Client` compartido.)
- `main.dart` ni su `HttpRemoteRepository(Client())` (fuera de scope).
- `_loadListAppearances` ni `_enrichVisits` (E3 es estructural/backend; no refactorizar aquí).
- `HttpRemoteRepository` (su lógica de caché y de cliente se mantiene).
- Los anchors `cerca-ahora-*`, el orden/filtrado observable de la lista, ni la UI.
- La inyección de `repository` de RestaurantDetail (param de tests intacto).

---

PROHIBIDO (rechazo automático del Evaluator):
- Cerrar `sharedHttpClient` en un `dispose` (lo dejaría inservible para otras pantallas).
- Seguir creando `http.Client()`/`Client()` por montaje en las 3 pantallas de detalle (E2 sin resolver).
- Dejar `Geolocator.distanceBetween` dentro del comparador del `sort` o recomputar la distancia en el builder de la lista de CercaAhora (E1 sin resolver).
- Cambiar el orden, el filtrado por radio o el formato del string de distancia (no debe haber cambio observable).
- Refactorizar/“optimizar” el N+1 de `_loadListAppearances` rompiendo su semántica (es estructural; no se toca).
- Escribir tests de widget que monten estas pantallas; tocar `pubspec.yaml`/`ios/`/`android/`/`main.dart`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze` limpio en los ficheros tocados (sólo se permiten los infos preexistentes de `withOpacity`/`Share` deprecados y los warnings ya-existentes de `visit_screen.dart` del bloque comentado ⑥⑦ que se limpian en el sprint F).
- Confirmar leyendo el diff: (E2) existe `sharedHttpClient` y las 3 pantallas lo reutilizan; ninguna crea `Client()` por montaje; nadie lo cierra. (E1) la distancia se computa una vez por restaurante y se reutiliza en filtro+sort+display; el comparador del sort NO llama `distanceBetween`.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: ~30 tests YA fallan ANTES de este sprint por infra preexistente (`widget_test.dart` template, `settings/login/listas/visitas` por `WebViewPlatform.instance`/remote-config/network mocks). NO son regresiones; no intentar arreglarlos aquí.

OUT OF SCOPE (mencionar en informe):
- **E3 N+1 real (list-appearances)**: requiere backend — o un endpoint `GET /restaurants/:id/list-appearances`, o incluir los `restaurantId` de miembros en el resumen de `getCuratedLists()`. Hoy el resumen `CuratedList` sólo trae `count`. Abrir ticket de backend; en cliente ya está paralelizado + cacheado + (tras E2) con conexión reutilizada.
- Memoizar `_computeFiltered` entre rebuilds (cache por `(all, loc, radius)`): mejora menor; el grueso es no recomputar la distancia dentro del sort. Follow-up.
- Migrar `main.dart` y los demás repos (`HttpFavoritesRepository`) al `sharedHttpClient`: consistencia deseable, otro sprint.
- `_enrichVisits` (N+1 acotado por nº de visitas, típicamente 1-3): no se toca.

ENTREGA:
1. Diff con los ficheros (1 nuevo + 3 pantallas de detalle con el client compartido + CercaAhora con el caching de distancia).
2. `flutter analyze` limpio (salvo infos preexistentes y warnings F-diferidos de visit_screen).
3. `flutter test` (suite existente) sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando E1/E2 por code-review y reconociendo E3 como backend/out-of-scope.

Diff objetivo ≤ 130 líneas.
