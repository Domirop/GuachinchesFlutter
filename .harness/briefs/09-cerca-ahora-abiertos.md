Añadir un **acceso directo "Cerca AHORA"** en el home que aplique en un solo tap dos filtros combinados: (a) `isOpen=true` (abierto ahora) y (b) ordenado/limitado por distancia a la ubicación del usuario.

CONTEXTO ACTUAL (verificado):

- `lib/data/cubit/restaurants/basic/restaurant_cubit.dart:44` — `getFilterRestaurants` ya acepta `bool isOpen=false`. Cuando es true, filtra por horarios.
- `lib/data/cubit/restaurants/map/restaurant_map_cubit.dart:55` — idem para mapa.
- `lib/ui/pages/new_home/new_home_body.dart:357` — `isOpenNow(r.horariosJson, now)` ya implementado para filtros locales.
- `LocationCubit` con states `LocationLoaded(lat, lng)`, `LocationDenied`, `LocationUnavailable`. Banner "Activar" cuando denied.
- Hay `NearbyRestaurantCard` y `NearbySection` (`lib/ui/components/nearby_section.dart`) que muestran "Cerca de ti" pero SIN filtro de abierto.
- Hoy hay quick-filter chips (`_QuickChip`) que filtran por type (tradicional/moderno) y openOnly, PERO se aplican sobre la lista cargada del home — no abren una pantalla dedicada.

OBJETIVO: dar un **call-to-action prominente** en el home que abra una pantalla full con la lista de "abiertos ahora + ordenados por distancia", como entry point primario.

CONTRATO FUNCIONAL:

1. **Crear `lib/ui/pages/cerca_abiertos/cerca_ahora_screen.dart`**:
   - Stateful, accepta opcional `int initialLimit = 30` y opcional `double maxRadiusKm = 5`.
   - AppBar "Abiertos cerca de ti" + back.
   - En `initState`:
     * Lee `LocationCubit` del context. Si NO está en `LocationLoaded`, muestra estado `_LocationRequired` con botón "Activar ubicación" (llama `locationCubit.requestLocation()` o navega a settings con `Geolocator.openAppSettings()` si está denied).
     * Si está loaded: lee `RestaurantCubit` y dispara `getFilterRestaurants(islandId: <del UserCubit / island actual>, isOpen: true)`.
   - Render:
     * Estados: loading (spinner), empty ("Nada abierto cerca ahora"), loaded (lista de `NearbyRestaurantCard`s ordenadas por distancia al user — calcular con `Geolocator.distanceBetween`), error.
     * Header con conteo: "X restaurantes abiertos a menos de Y km" (donde Y es `maxRadiusKm`).
     * Pull-to-refresh: re-pide la query y re-calcula distancia (en caso de que el user se haya movido o cambien horarios).
   - Anchors:
     * `cerca-ahora-screen-root`
     * `cerca-ahora-list`
     * `cerca-ahora-empty`
     * `cerca-ahora-location-required`
     * `cerca-ahora-activate-location-button`

2. **Añadir CTA en el home** (`lib/ui/pages/new_home/new_home_body.dart` o `new_home_screen.dart`):
   - Componente nuevo: un **chip/card grande "🟢 Abiertos cerca AHORA"** prominente, ubicado JUSTO DEBAJO del hero ("BUENOS DÍAS / TARDES / NOCHES"), antes de la primera sección de cards.
   - Visual: card horizontal con icono (`Icons.bolt` o `Icons.access_time_filled`), texto "Abiertos cerca AHORA" en bold, subtítulo "Toca para ver disponibles", chevron a la derecha. Color de acento `AppColors.sol` (canario, llamativo).
   - Tap → `Navigator.push(MaterialPageRoute(builder: (_) => CercaAhoraScreen()))`.
   - Anchor: `home-cerca-ahora-cta`.
   - **NO** desplazar el resto del layout existente más de lo necesario — el componente ocupa ~80px de alto.

3. **Filtrado por radio en cliente**: tras recibir la lista del backend, filtrar localmente por `Geolocator.distanceBetween(userLat, userLng, r.lat, r.lng) <= maxRadiusKm * 1000`. Los que pasen se ordenan ascendente por distancia. Si tras filtrar quedan 0 resultados PERO el backend devolvió >0, mostrar empty state especial: "Nada abierto a menos de Xkm. Aumentar radio." con un botón que duplica el radio y vuelve a filtrar (sin pedir al backend).

4. **Pull-to-refresh** en `cerca_ahora_screen.dart`: `RefreshIndicator` que invalida caché (`'restaurants:'` prefix con `invalidateCache` del sprint #4) y re-pide.

5. **Telemetría mínima** (aprovechando `firebase_analytics` ya en deps):
   ```dart
   FirebaseAnalytics.instance.logEvent(name: 'cerca_ahora_opened', parameters: {
     'has_location': hasLoc ? 1 : 0,
   });
   FirebaseAnalytics.instance.logEvent(name: 'cerca_ahora_result_count', parameters: {
     'count': filteredList.length,
   });
   ```

ANCHORS (kebab-case, identifier):
- `home-cerca-ahora-cta`
- `cerca-ahora-screen-root`
- `cerca-ahora-list`
- `cerca-ahora-empty`
- `cerca-ahora-location-required`
- `cerca-ahora-activate-location-button`

TESTS OBLIGATORIOS:

- `test/ui/pages/cerca_abiertos/cerca_ahora_screen_test.dart`:
  * Render con `LocationDenied` → muestra `cerca-ahora-location-required` y el botón.
  * Render con `LocationLoaded` + cubit en `RestaurantLoaded([restaurant1, restaurant2])` (mock) → muestra la lista y el conteo.
  * Render con resultados vacíos del backend → empty state genérico.
  * Render con backend OK pero filtro local deja 0 → empty state "Aumentar radio" con botón.
  * Tap en CTA del home → empuja `CercaAhoraScreen`.

- `test/cubit/restaurant_cubit_open_test.dart` (si no existe ya un test de isOpen):
  * `getFilterRestaurants(isOpen: true)` solo emite restaurantes con horario abierto en `DateTime.now()` (mockear `now` si es necesario inyectando un clock).

PROHIBIDO:
- Modificar `pubspec.yaml`, ios/, android/.
- Cambiar la API del `RestaurantCubit` (ya tiene `isOpen` param — usar tal cual).
- Cambiar el diseño del home más allá de añadir 1 componente CTA en la posición indicada.
- Mostrar el CTA cuando el user no haya completado onboarding (verificar `OnboardingCubit` si existe; si no, sin guard).
- Bloquear el CTA cuando `LocationDenied` — debe ser visible siempre; la pantalla destino gestiona el caso.

OUT OF SCOPE:
- Cambiar el cálculo de `isOpenNow` (ya existe).
- Refactorizar `NearbySection` para reusar lógica.
- Mapa en esta pantalla (es lista; el mapa ya está en tab Mapa).
- Notificación push cuando algo nuevo abra cerca (futuro).
- Permitir customizar `maxRadiusKm` desde Settings (hoy hardcoded 5km, el botón de "aumentar" duplica).

ENTREGA: `flutter analyze` limpio, tests verdes (cerca_ahora_screen_test + restaurant_cubit_open_test si nuevo). El CTA debe ser visible al cargar el home en simulador sin tocar nada. Resumen del generator: número de líneas añadidas y dónde se coloca el CTA exactamente.
