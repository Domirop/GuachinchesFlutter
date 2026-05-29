Cablear los 2 `TODO(nav)` de Settings que hoy no navegan a nada: "Mis valoraciones" y "Favoritos guardados".

CONTEXTO ACTUAL (verificado):

- `lib/ui/pages/settings/settings_screen.dart:471` — `_SettingsRow` "Mis valoraciones" tiene `onTap: () { // TODO(nav): navigate to valoraciones screen }`. No hace nada al pulsar.
- `lib/ui/pages/settings/settings_screen.dart:483` — `_SettingsRow` "Favoritos guardados" tiene `onTap: () { // TODO(nav): navigate to favoritos screen }`. Idem.
- `lib/ui/pages/valoraciones/valoraciones.dart` exporta `ValoracionesPage` (StatefulWidget, ya tiene `_StatsHeader` y demás). No requiere argumentos.
- `lib/ui/pages/favoritos/favoritos.dart` exporta `FavoritosPage` (StatefulWidget). Verificar constructor — probablemente sin args también.
- El subtitle de Favoritos dice hardcoded "8 guachinches guardados" — ese conteo no es real, viene literal. **No** es objetivo de este brief arreglar el conteo (out of scope), solo la navegación. Pero sí marcar TODO si está hardcoded.

CONTRATO FUNCIONAL:

1. **Reemplazar el `onTap` de "Mis valoraciones"** (settings_screen.dart:471):
   ```dart
   onTap: () {
     Navigator.push(
       context,
       MaterialPageRoute(builder: (_) => const ValoracionesPage()),
     );
   },
   ```
   Añadir el import correspondiente arriba: `import 'package:guachinches/ui/pages/valoraciones/valoraciones.dart';`

2. **Reemplazar el `onTap` de "Favoritos guardados"** (settings_screen.dart:483):
   ```dart
   onTap: () {
     Navigator.push(
       context,
       MaterialPageRoute(builder: (_) => const FavoritosPage()),
     );
   },
   ```
   Import: `import 'package:guachinches/ui/pages/favoritos/favoritos.dart';`

3. **Si `ValoracionesPage` o `FavoritosPage` requieren parámetros que el contexto de Settings no tiene fácilmente** (p.ej. el `userId`), leerlos del `UserCubit` ya inyectado en `_SettingsScreenState` o del secure storage (mismo patrón que `_presenter.loadUser()`). NO inventar params si las pantallas no los exigen — verificar constructor primero.

4. **Anchors `Semantics(identifier:)`** en las 2 filas de Settings (para tests futuros):
   - Envolver "Mis valoraciones" con `Semantics(identifier: 'settings-my-ratings-row', child: ...)`
   - Envolver "Favoritos guardados" con `Semantics(identifier: 'settings-favorites-row', child: ...)`

5. **Subtitle hardcoded "8 guachinches guardados"**: si el conteo está literal, dejar un `TODO(backend): wire real count from favorites cubit` al lado pero NO refactorizar.

TESTS OBLIGATORIOS:

- `test/ui/pages/settings/settings_navigation_test.dart`:
  * Build `SettingsScreen` con mocks mínimos (`MockUserCubit`, `MockRemoteRepository`).
  * Tap en `settings-my-ratings-row` → verifica que `Navigator` empuja una ruta y que la nueva ruta contiene un widget de tipo `ValoracionesPage`.
  * Idem para `settings-favorites-row` → `FavoritosPage`.
  * Usar `MaterialApp` con `navigatorObservers: [observer]` y un `MockNavigatorObserver` para asertar el push, o `find.byType(ValoracionesPage)` tras `pumpAndSettle`.

PROHIBIDO:
- Modificar `pubspec.yaml`, ios/, android/.
- Cambiar la UI de `ValoracionesPage` o `FavoritosPage` (out of scope — solo navegación).
- Arreglar el subtitle hardcoded "8 guachinches" (solo marcar TODO).
- Romper tests existentes de Settings (si los hay).
- Inventar parámetros que las pantallas destino no requieren.

OUT OF SCOPE:
- Refactorizar Settings (1791 líneas — otro sprint).
- Wire del conteo real de favoritos.
- Navegación de retorno custom (basta con el back default del AppBar de cada pantalla).

ENTREGA: diff que pase `flutter analyze` y `flutter test test/ui/pages/settings/settings_navigation_test.dart` verde. Resto de tests verdes. En el resumen del generator: confirmar que los 2 imports y los 2 onTaps están bien y que los anchors están en kebab-case.
