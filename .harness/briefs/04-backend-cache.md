Añadir caché stale-while-revalidate a `HttpRemoteRepository` para reducir latencia percibida y permitir un modo "offline básico" cuando no hay red.

CONTEXTO ACTUAL (verificado):

- `lib/data/HttpRemoteRepository.dart` tiene 1092 líneas, mayoría de métodos sin caché.
- Único caché existente: `lib/data/services/weather_service.dart:82-92` (TTL 30 min) — referencia de patrón, NO modificar.
- `sqflite` ya está en pubspec, ya hay un `SqlLiteLocalRepository` en `lib/data/local/sql_lite_local_repository.dart` (usar como ejemplo de cómo se inicializa la base).
- `flutter_cache_manager` está en pubspec pero NO se usa — no usarlo, no encaja con respuestas JSON (es para blobs).

CONTRATO FUNCIONAL:

1. **Crear `lib/data/local/http_cache_store.dart`**:
   - Clase `HttpCacheStore` con singleton lazy (`HttpCacheStore.instance`) y constructor inyectable para tests (`HttpCacheStore.test(Database db)`).
   - Tabla SQLite: `http_cache(key TEXT PRIMARY KEY, body TEXT NOT NULL, ts INTEGER NOT NULL)`. Inicializar en `_initDb()` con `openDatabase(version: 1, onCreate)`.
   - API:
     ```dart
     /// Returns body if present and not older than [maxAge]. Returns null otherwise.
     Future<String?> read(String key, {required Duration maxAge});

     /// Returns body if present (regardless of age). Returns null if not present.
     Future<String?> readStale(String key);

     /// Stores body for key. Overwrites any existing entry.
     Future<void> write(String key, String body);

     /// Deletes all entries whose key starts with [prefix]. Returns rows affected.
     Future<int> invalidate(String prefix);

     /// Deletes everything. For tests / logout.
     Future<void> clear();
     ```
   - Persistir `ts` como `DateTime.now().millisecondsSinceEpoch`.
   - `read(maxAge)` debe `WHERE ts > ?` con `now - maxAge.inMilliseconds`.

2. **Crear `lib/data/HttpCachePolicy.dart`** con constantes de TTL agrupadas:
   ```dart
   class HttpCachePolicy {
     static const listTtl = Duration(hours: 1);
     static const detailTtl = Duration(minutes: 30);
     static const referenceTtl = Duration(hours: 6); // categorías/islas/tipos cambian raro
   }
   ```

3. **Modificar `lib/data/HttpRemoteRepository.dart`**:
   - Importar `HttpCacheStore` y `HttpCachePolicy`.
   - Instancia `final _cache = HttpCacheStore.instance;` como campo del repo.
   - Envolver los siguientes métodos con patrón **stale-while-revalidate**:
     * `getAllRestaurants(int number, [String islandId])` → key = `"restaurants:all:$islandId:from$number"`, TTL = `listTtl`
     * `getRestaurantById(String id)` → key = `"restaurant:detail:$id"`, TTL = `detailTtl`
     * `getCategories()` → key = `"categories"`, TTL = `referenceTtl`
     * `getMunicipalities()` (si existe) o `getSimpleMunicipalities()` → key = `"municipalities"`, TTL = `referenceTtl`
     * `getIslands()` → key = `"islands"`, TTL = `referenceTtl`
     * `getTypes()` → key = `"types"`, TTL = `referenceTtl`
   - **Patrón a aplicar** en cada uno:
     ```dart
     Future<X> getX(...) async {
       final key = 'x:...';
       final cached = await _cache.read(key, maxAge: HttpCachePolicy.YTtl);
       if (cached != null) {
         // Fire-and-forget background refresh; don't await
         unawaited(_refreshXInBackground(key, ...));
         return X.fromJson(json.decode(cached));
       }
       // No fresh cache → network with timeout
       final response = await _client.get(uri).timeout(const Duration(seconds: 15));
       if (response.statusCode >= 200 && response.statusCode < 300) {
         await _cache.write(key, response.body);
         return X.fromJson(json.decode(response.body));
       }
       // Stale fallback if network fails
       final stale = await _cache.readStale(key);
       if (stale != null) return X.fromJson(json.decode(stale));
       throw Exception('getX failed: ${response.statusCode}');
     }
     ```
   - Helper `_refreshXInBackground` hace lo mismo que la rama "no fresh cache" pero envuelto en try/catch silencioso (es background, no debe propagar).
   - Usar `import 'dart:async';` para `unawaited`.
   - **NO modificar la firma pública** de los métodos (mantener mismo nombre, mismos params, mismo return type).
   - **NO añadir try/catch genérico que trague errores** — si network falla Y no hay stale, propagar la excepción como antes.

4. **Método público de invalidación en `RemoteRepository` (abstract) y `HttpRemoteRepository` (impl)**:
   ```dart
   /// Invalidates HTTP cache entries whose key starts with [prefix].
   /// Examples: 'restaurants:', 'categories', 'islands'.
   Future<void> invalidateCache(String prefix);
   ```
   En `HttpRemoteRepository`: `Future<void> invalidateCache(String prefix) => _cache.invalidate(prefix);`
   En `RemoteRepository` abstract: solo la declaración.

5. **Integrar invalidación con pull-to-refresh existentes (4 pantallas)**:
   - Home (`new_home_screen.dart:_onPullRefresh`): añadir `await context.read<RemoteRepository>().invalidateCache('restaurants:');` ANTES de `_presenter.bootstrap(...)`.
   - Listas (`listas_screen.dart`): añadir `invalidateCache('categories')` ANTES de `curatedListsCubit.refresh(...)`. (Las curated lists no se cachean en este sprint, pero sí podrían depender de categorías.)
   - Mapa (FAB): añadir `invalidateCache('restaurants:')` ANTES de `restaurantsCubit.refresh()`.
   - Perfil: NO invalidar nada (UserCubit no se cachea).

   Si `RemoteRepository` no se inyecta vía Provider/BlocProvider en la pantalla, usar el `HttpRemoteRepository(Client())` local como ya hacen esas pantallas (sí, es feo, pero out-of-scope refactorizarlo).

6. **Inicialización en `lib/main.dart`**:
   - Antes del `runApp`, llamar `await HttpCacheStore.instance.init();` (si la clase requiere init explícito por sqflite; si no, no hace falta — sqflite suele inicializarse lazy en el primer `openDatabase`).
   - Si no requiere init explícito, omitir este paso.

ANCHORS / aspectos no-UI: no aplica (esta tarea es de capa de datos).

TESTS OBLIGATORIOS:

- `test/data/local/http_cache_store_test.dart`:
  * `write` + `read(maxAge: 1h)` → devuelve el body recién escrito.
  * `write` + `read(maxAge: 0ms)` → devuelve null (expirado).
  * `write` + `readStale` → devuelve el body sin importar edad.
  * `read` sobre key inexistente → null.
  * `write` dos veces sobre la misma key → overwrite (no duplicate).
  * `invalidate('restaurants:')` borra solo claves que empiezan por ese prefijo, deja intactas las otras.
  * `clear()` deja la base vacía.
  * Usar `sqflite_common_ffi` si está disponible para correr en VM; si no, marcar tests como `@TestOn('vm')` y usar mock. Si requiere paquete nuevo, NO añadirlo — escribir tests con un fake in-memory implementando la misma API.

  **Recomendación**: hacer `HttpCacheStore` con un campo `_storage` que sea una interfaz `_Storage` con `Future<String?> get(String)`, `Future<void> put(String, String, int)`, `Future<int> delete(String)`. Tener dos implementaciones: `_SqliteStorage` (prod) y exponer un constructor `HttpCacheStore.withStorage(_Storage)` para tests con un fake. Así los tests no dependen de sqflite.

- `test/data/http_remote_repository_cache_test.dart`:
  * Test del wrapper para 1 método (basta con `getCategories`): primera llamada → hace network + escribe cache. Segunda llamada inmediata → devuelve cache, NO hace network. Tras `invalidateCache('categories')` → tercera llamada hace network de nuevo.
  * Inyectar `Client` mock (ya existe el patrón http.Client en el repo) Y `HttpCacheStore.withStorage(_FakeStorage)`.
  * NO testear los 6 endpoints; con 1 que demuestre el patrón basta.

PROHIBIDO:
- Modificar `pubspec.yaml`.
- Tocar ios/ o android/.
- Añadir paquete `sqflite_common_ffi`, `path_provider` extra, ni ningún otro.
- Cambiar firmas públicas de `RemoteRepository` (excepto añadir `invalidateCache`).
- Romper los tests existentes (correr `flutter test` al final y confirmar verdes).
- Cachear endpoints de auth, user, reviews, favoritos.
- Usar `flutter_cache_manager` (no encaja con JSON).
- Tragar excepciones de red silenciosamente: si network falla Y no hay stale, propagar.

OUT OF SCOPE:
- Caché de imágenes (ya lo hace `cached_network_image`).
- Invalidación cross-device (push del backend).
- Métricas de hit-rate / observabilidad del caché.
- Refactorizar `HttpRemoteRepository` (eliminar prints, añadir timeouts globales, etc. — eso es la tarea de logging, otro sprint).
- Inyectar `RemoteRepository` vía BlocProvider en todas las pantallas (sigue siendo `HttpRemoteRepository(Client())` local donde ya lo es).

ENTREGA: diff que pase `flutter analyze` (sin nuevos errores fatales) y `flutter test test/data/local/http_cache_store_test.dart test/data/http_remote_repository_cache_test.dart` verde. Resto de tests existentes deben seguir pasando.
