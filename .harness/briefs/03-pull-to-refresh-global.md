Añadir pull-to-refresh (RefreshIndicator) en las 4 pantallas principales que aún no lo tienen: home (Explora), listas, mapa y perfil. Las otras 3 (discover, favoritos, visitas) ya lo tienen — usar como patrón de referencia.

CONTEXTO ACTUAL (verificado):

Pantallas YA con pull-to-refresh (referencia de estilo):
- `lib/ui/pages/discover/discover_screen.dart`
- `lib/ui/pages/favoritos/favoritos.dart`
- `lib/ui/pages/visitas/visitas_screen.dart` (creada en tarea anterior, usa `_UserVisitsCubit.refresh()`)

Pantallas SIN pull-to-refresh y los cubits relevantes:

1. **Home / Explora** — `lib/ui/pages/new_home/new_home_screen.dart`
   Cubits relevantes (cargan datos del backend): `RestaurantCubit`, `NewHomeFiltersCubit`, `WeatherCubit`, `ZoneWeatherCubit`, `ZonesCubit`, `CuratedListsCubit`, `VisitsCubit`.
   Refresh debería re-invocar el bootstrap del presenter (probablemente hay un `loadAll()` / `bootstrap()` en el presenter; si no, llamar a los métodos de carga de los cubits primarios: restaurantes nearby + weather + zonas + curated lists).

2. **Listas** — `lib/ui/pages/listas/listas_screen.dart`
   Cubits: `CuratedListsCubit`, `NewHomeFiltersCubit`. Refresh recarga las listas curadas.

3. **Mapa** — `lib/ui/pages/map/map_search.dart`
   Cubits: `MenuCubit`, `RestaurantMapCubit`. Refresh recarga restaurantes visibles + filtros del menú.
   **Cuidado**: el mapa es un widget grande con `GoogleMap` dentro; el `RefreshIndicator` debe envolver el bottom sheet de resultados o un ListView de cards, NO el `GoogleMap` directamente (no se puede arrastrar un map widget hacia abajo sin romper el gesto).

4. **Perfil** — `lib/ui/pages/profile/profile_v2.dart`
   Cubits: `OnboardingCubit`, `ThemeCubit`, `UserCubit`.
   Refresh aquí refresca `UserCubit` (info del usuario desde backend: nombre, avatar, conteo de favoritos/visitas si aplica). El theme y onboarding son locales — no se refrescan.
   Si `UserCubit` no tiene método de refresh remoto, añadir uno: `Future<void> refreshFromBackend()` que invoque el mismo endpoint que el load inicial.

CONTRATO FUNCIONAL:

Para cada una de las 4 pantallas:

1. Envolver el contenido scrollable principal (CustomScrollView / ListView / SingleChildScrollView con AlwaysScrollableScrollPhysics) en un `RefreshIndicator` con `onRefresh: () async { ... }`.

2. El `onRefresh` debe:
   - Llamar al/los métodos de refresh del cubit primario de la pantalla.
   - Esperar a que termine (await). No fire-and-forget.
   - Si hay varios cubits que refrescar en paralelo, usar `await Future.wait([cubit1.refresh(), cubit2.refresh()])`.

3. Estilo del RefreshIndicator: respetar `context.brand` (color del spinner = accent del brand). Si no se puede inferir el accent en dark mode, usar `Theme.of(context).colorScheme.primary` como fallback.

4. Si el cubit no tiene método de refresh idempotente, añadirlo. El nombre canónico es `refresh()` (sin args, idempotente, vuelve a llamar al endpoint y emite nuevo state). NO usar `load()` directamente porque algunos load resetean state a Loading (parpadeo visual) — en `refresh` mantener el state anterior visible hasta que llega el nuevo data.

5. `ScrollPhysics`: si la pantalla actual usa `NeverScrollableScrollPhysics` o `ClampingScrollPhysics`, cambiar a `AlwaysScrollableScrollPhysics` (o `BouncingScrollPhysics` para iOS) para que el RefreshIndicator funcione incluso con pocos items.

6. **Mapa específicamente**: NO envolver el `GoogleMap` con RefreshIndicator. Envolver solo el bottom sheet de resultados (la lista de restaurantes cercanos) o añadir un botón flotante "Actualizar zona" si arquitecturalmente no encaja un pull-to-refresh.

ANCHORS de a11y para tests (kebab-case en inglés):
- `'home-refresh-indicator'`
- `'listas-refresh-indicator'`
- `'mapa-refresh-indicator'` (sobre el bottom sheet de resultados, no sobre el map)
- `'perfil-refresh-indicator'`

TESTS OBLIGATORIOS:

- `test/ui/pages/new_home/home_pull_to_refresh_test.dart`: gesto de drag-down sobre 'home-refresh-indicator' dispara `RestaurantCubit.refresh()` (o el método primario equivalente). Verificar con mock del cubit.
- `test/ui/pages/listas/listas_pull_to_refresh_test.dart`: idem con `CuratedListsCubit`.
- `test/ui/pages/map/mapa_pull_to_refresh_test.dart`: idem con `RestaurantMapCubit`, comprobando que el RefreshIndicator NO envuelve el GoogleMap (sino el sheet de resultados).
- `test/ui/pages/profile/perfil_pull_to_refresh_test.dart`: idem con `UserCubit.refreshFromBackend()`.

Cada test debe verificar:
1. El `RefreshIndicator` está presente y tiene el `Semantics(identifier:)` correcto.
2. El gesto dispara el método esperado del cubit.
3. La pantalla no entra en estado `Loading` durante el refresh (el state previo sigue visible).

PROHIBIDO:
- Modificar `pubspec.yaml`.
- Tocar ios/ o android/.
- Cambiar la arquitectura de los cubits (solo añadir método `refresh()` si no existe).
- Romper layouts existentes — el RefreshIndicator debe ser puramente aditivo.
- Envolver `GoogleMap` con RefreshIndicator (rompe gestos del map).
- Duplicar lógica de carga: si el cubit ya tiene `load()`, `refresh()` debe delegar internamente sin re-implementar.
- Usar `Semantics(label:)` como anchor técnico — solo `identifier`.

OUT OF SCOPE:
- Refresh automático periódico (no es lo que pide la tarea).
- Skeleton loaders durante el refresh (el indicador del RefreshIndicator es suficiente).
- Refrescar al volver al foreground (eso es otra issue).

ENTREGA: diff que pase `flutter analyze` y `flutter test` sin warnings, con las 4 pantallas con pull-to-refresh funcional y 4 tests nuevos (uno por pantalla).
