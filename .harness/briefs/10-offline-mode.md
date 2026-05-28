Habilitar **modo offline real** aprovechando el `HttpCacheStore` del sprint #4 + persistencia de favoritos y últimas visitas, con banner visual cuando hay red caída.

CONTEXTO ACTUAL (verificado):

- Sprint #4 dejó `HttpCacheStore` con `read(key, maxAge)` y `readStale(key)`. Hoy `HttpRemoteRepository` cae a `readStale` SOLO si la network call lanza excepción (intuitive fallback).
- NO existe paquete de connectivity. NO hay banner ni estado UI que comunique "estás offline".
- NO existe cubit de favoritos persistido — Favorites probablemente vivan solo en backend o no se cargan al arranque sin red.
- `UserVisits` se carga de `getUserVisits` pero sin caché propio. Tras sprint #4 los GETs de restaurantes están cacheados pero los user-scoped (visits, favoritos, votos) NO.

OBJETIVO: que un user con la app **previamente abierta** (cualquier cache caliente) pueda, sin red:
1. Ver el home con últimas listas cargadas (stale ok).
2. Ver detalle de restaurantes que ya consultó.
3. Ver sus favoritos.
4. Ver sus últimas visitas.
5. Recibir feedback visual claro de que está offline (banner persistente).
6. Reintentar automáticamente cuando vuelva la red.

CONTRATO FUNCIONAL:

1. **pubspec.yaml** (excepción justificada): añadir
   ```yaml
   connectivity_plus: ^5.0.2
   ```
   (versión compatible con Flutter 3.35; si la 5.x da problemas con plugins iOS, fallback a 4.x.)

2. **Crear `lib/core/connectivity/connectivity_cubit.dart`** + `connectivity_state.dart`:
   - States: `ConnectivityOnline`, `ConnectivityOffline`.
   - `Connectivity().onConnectivityChanged.listen(...)` — emite states según el resultado.
   - Método `init()` lee estado inicial al arranque.
   - Inyectar como BlocProvider en `lib/main.dart` arriba del MaterialApp.

3. **Crear `lib/ui/components/offline_banner.dart`**:
   - Widget que escucha `ConnectivityCubit`. Si `ConnectivityOffline`, muestra una `MaterialBanner` no-dismissable arriba de la app con texto "Sin conexión — mostrando datos guardados" e icono `Icons.wifi_off`. Color `AppColors.mojo` (cálido / atención).
   - Se monta en el `Scaffold` raíz / en el `NewHomeTabScaffold` para que sea visible en todas las tabs.
   - Anchor: `offline-banner`.
   - Cuando vuelve a online, banner desaparece con animación slide-up.

4. **Persistencia de favoritos (nuevo cubit + storage)**:
   - **Crear `lib/data/cubit/favorites/favorites_cubit.dart`** + state files:
     * States: `FavoritesInitial`, `FavoritesLoading`, `FavoritesLoaded(List<String> restaurantIds, {bool fromCache})`, `FavoritesError`.
     * Métodos:
       - `loadFavorites(String userId)` — primero lee del local (sqflite via tabla nueva `favorites(user_id, restaurant_id, ts)`), emite `FavoritesLoaded(localList, fromCache: true)`, luego intenta refrescar del backend (`getUserFavorites` si existe; si NO, marcar TODO y solo usar local). Si backend OK, emite `FavoritesLoaded(remoteList, fromCache: false)` y actualiza local.
       - `addFavorite(String userId, String restaurantId)` — añade local inmediato (optimistic), llama backend; si falla, **mantiene local** (sync diferido) y marca pending. NO rollback inmediato.
       - `removeFavorite(String userId, String restaurantId)` — idem.
   - **Tabla SQLite nueva**: añadir a `SqlLiteLocalRepository` o a un wrapper:
     ```sql
     CREATE TABLE favorites(
       user_id TEXT NOT NULL,
       restaurant_id TEXT NOT NULL,
       ts INTEGER NOT NULL,
       sync_pending INTEGER NOT NULL DEFAULT 0,
       PRIMARY KEY(user_id, restaurant_id)
     );
     CREATE INDEX idx_favorites_pending ON favorites(sync_pending) WHERE sync_pending = 1;
     ```
   - **Background sync**: cuando `ConnectivityCubit` emite `ConnectivityOnline`, el `FavoritesCubit` debe disparar `_syncPending()` que itera por filas con `sync_pending=1` y las manda al backend, marcándolas a 0 si OK.

5. **Persistencia de visitas locales**: las visitas que el user ya cargó (`UserVisitsCubit` → `UserVisitsLoaded(visits)`) deben cachearse igual:
   - Modificar `UserVisitsCubit.loadVisits(userId)`:
     1. Lee de cache local primero (sqflite nueva tabla `user_visits_cache` o reuso de `HttpCacheStore` con key `'visits:user:$userId'`), emite stale.
     2. Intenta backend. Si OK, emite fresh y persiste.
     3. Si backend falla Y hay cache, mantiene el stale emitido (no emite Error).
     4. Si NO hay cache Y backend falla, emite `UserVisitsError`.

6. **Cache TTL del repo HTTP**: el sprint #4 dejó `readStale` para fallback en excepción de red. Aprovecharlo más:
   - En `HttpRemoteRepository._withSwr`, si `ConnectivityCubit` (vía un singleton o inyección) está en `ConnectivityOffline`, **saltar la llamada de red** y devolver `readStale` directamente (más rápido y no malgastas timeout).
   - Si no hay manera limpia de acceder al cubit desde el repo (sería un coupling feo), alternativa: que el método chequee `Connectivity().checkConnectivity()` previo y si es `none`, vaya directo a stale.

7. **Loading states** en pantallas core (home, listas, mapa, profile):
   - Cuando muestran data desde caché stale + el `ConnectivityCubit` está offline, mostrar un sub-label "Mostrando datos guardados" donde el usuario pueda intuir que no es fresco. Discreto, no intrusivo.

ANCHORS:
- `offline-banner`

TESTS OBLIGATORIOS:

- `test/core/connectivity_cubit_test.dart`:
  * `init()` con stream que emite `ConnectivityResult.wifi` → state `ConnectivityOnline`.
  * Stream emite `ConnectivityResult.none` → state `ConnectivityOffline`.
  * Stream emite secuencia [none, wifi] → states [offline, online].
  * Usar fake stream controllable.

- `test/cubit/favorites_cubit_test.dart`:
  * `loadFavorites` con local hits → emite `FavoritesLoaded(localList, fromCache: true)` PRIMERO.
  * `addFavorite` con backend OK → local + backend, no pending.
  * `addFavorite` con backend KO → local, pending=1.
  * `_syncPending` itera y marca como sincronizadas las que el backend acepta.
  * Inyectar fake repo + fake storage (no sqflite real).

- `test/ui/components/offline_banner_test.dart`:
  * Banner ausente cuando `ConnectivityOnline`.
  * Banner presente con texto correcto y anchor cuando `ConnectivityOffline`.

PROHIBIDO:
- Cachear endpoints de auth, user info, reviews ni votos (siguen requiriendo red — esto es la lista NO-cache del sprint #4).
- Tragar errores de backend silenciosamente. Si algo falla Y no hay cache, emite Error con AppLogger.warn loggeado.
- Romper tests existentes del sprint #4 (`http_cache_store_test`, `http_remote_repository_cache_test`).
- Mostrar el banner de offline durante el splash inicial (esperar a que `ConnectivityCubit.init()` haya leído estado).
- Implementar sync conflict resolution complejo (last-write-wins en local es suficiente por ahora).

OUT OF SCOPE:
- Detección de "red conectada pero sin internet real" (captive portals) — `connectivity_plus` solo detecta wifi/cellular, no si hay internet de verdad.
- Cola persistente de mutaciones (votos, comentarios) en offline — solo favoritos por ahora.
- Indicar fecha exacta del snapshot stale ("Última actualización: hace 2h") — solo el genérico "Mostrando datos guardados".
- Modo avión simulado en debug builds.
- Pre-fetch agresivo en background al estar online (sería futuro: descargar top-50 de la isla actual para garantizar offline).

ENTREGA: `flutter analyze` limpio, todos los nuevos tests verdes, tests del sprint #4 siguen verdes. Banner se muestra correctamente al desactivar wifi del simulador. Favoritos añadidos offline persisten al reabrir la app y se sincronizan cuando vuelve la red.
