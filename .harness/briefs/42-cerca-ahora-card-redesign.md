Pantalla **Abiertos cerca de ti** (`lib/ui/pages/cerca_abiertos/cerca_ahora_screen.dart`). Tarea: **rediseñar las tarjetas de la lista al sistema de diseño nuevo** (crema/`context.brand.*` + acentos `AppColors`). Hoy la pantalla pinta `NearbyRestaurantCard` (tarjeta **vertical de 240px**, tema **oscuro** con `GlobalMethods.bgColorFilter`, textos `Colors.white`, pill `GlobalMethods.blueColor`, placeholder `Colors.white10`) **estirada a ancho completo** dentro de un `ListView.separated` → se ve como "diseño antiguo" (cards oscuras sobre fondo crema, medio vacías). Además navega al `Details` legacy.

Objetivo: una **tarjeta horizontal full-width** (estilo fila: thumbnail a la izquierda + info a la derecha) con tokens del tema nuevo, que navega al `RestaurantDetailScreen` nuevo. Cliente-puro. Verificación por **code-review + `flutter analyze`** + suite existente sin nuevos fallos. **NO tests de widget** que monten la pantalla.

Ficheros a tocar:
1. **NUEVO** `lib/ui/components/cards/cerca_ahora_list_card.dart` — el card nuevo.
2. `lib/ui/pages/cerca_abiertos/cerca_ahora_screen.dart` — cambiar import + uso (`NearbyRestaurantCard(...)` → card nuevo).

**NO TOCAR** `lib/ui/components/cards/nearby_restaurant_card.dart` (lo sigue usando la sección "Cerca de ti" del home en horizontal; su rediseño es follow-up fuera de scope). **NO TOCAR** `pubspec.yaml`, `ios/`, `android/`, `main.dart`, cubits, presenter, ni otras pantallas.

---

CONTEXTO (verificado leyendo el código):

- En `cerca_ahora_screen.dart` (~línea 314-358, método `_buildListOrEmpty`) el `ListView.separated` hace, por item:
  ```dart
  final entry = filtered[i];
  final distM = entry.distanceMeters;
  final distStr = distM < 1000
      ? '${distM.toStringAsFixed(0)} m'
      : '${(distM / 1000).toStringAsFixed(1)} km';
  return NearbyRestaurantCard(
    restaurant: entry.restaurant,
    distance: distStr,
  );
  ```
  → El nuevo card debe recibir `restaurant` (`Restaurant`) y `distance` (`String` ya formateado).
- El tema correcto ya se usa en el resto de la pantalla: `context.brand.base/surface/textPrimary/...` (extensión `BrandColorsContext` en `lib/config/brand_colors.dart`).
- Patrón de diseño NUEVO canónico = la tarjeta flotante del mapa `_FloatingMapCard` (`lib/ui/pages/map/map_search.dart` ~1823): thumbnail redondeado; nombre `brand.textPrimary` w700; **pill de distancia** `AppColors.atlantico.withOpacity(0.10)` con icono+texto `AppColors.atlantico`; **estrella** `AppColors.sol` + rating; **placeholder** = `Icon(Icons.restaurant, color: brand.textMuted)` sobre fondo claro (NUNCA caja oscura). Navega con `Navigator.push(MaterialPageRoute(builder: (_) => RestaurantDetailScreen(id: r.id)))`.
- Modelo `Restaurant` (campos disponibles): `id` (String), `nombre`, `municipio`, `mainFoto` (String, puede venir vacío), `avgRating` (double), `horariosJson`, `open`, `lat`, `lon`.
- Componente reusable `OpenStatusBadge(horariosJson:, fallbackOpen:)` (`lib/ui/components/open_status_badge.dart`) — REUSAR para el estado abierto/cerrado.
- `RestaurantDetailScreen({required String id})` en `lib/ui/pages/restaurant_detail/restaurant_detail_screen.dart`.

---

CONTRATO FUNCIONAL:

**A. Nuevo widget `CercaAhoraListCard`** (`StatelessWidget`) en el fichero nuevo:

```dart
class CercaAhoraListCard extends StatelessWidget {
  final Restaurant restaurant;
  final String distance; // ya formateado, p.ej. "850 m" / "2,3 km"
  const CercaAhoraListCard({super.key, required this.restaurant, required this.distance});
  ...
}
```

Layout (fila full-width, tema nuevo):
- Raíz: `GestureDetector(onTap: ...)` → `Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailScreen(id: restaurant.id)))`.
- Contenedor: `color: context.brand.surface`, `borderRadius: 16`, `border: Border.all(color: context.brand.border)`, contenido recortado (`ClipRRect`/`clipBehavior`). Altura coherente (~96-104px de imagen/fila).
- `Row`:
  - **Thumbnail** ~96x96, esquinas redondeadas: `Image.network(restaurant.mainFoto, fit: BoxFit.cover, errorBuilder: ...)` cuando `mainFoto.isNotEmpty`, si no o si falla → **placeholder claro**: contenedor `color: context.brand.elevated` con `Icon(Icons.restaurant, color: context.brand.textMuted, size: 32)` centrado. (NADA de `Colors.white10`/cajas oscuras.)
  - `SizedBox(width: 12)`.
  - **Info** `Expanded(child: Column(crossAxisAlignment: start, mainAxisAlignment: center))`:
    - **Pill de distancia** (arriba): `AppColors.atlantico.withOpacity(0.10)` de fondo, `borderRadius: 999`, `Icon(Icons.place_rounded, size: 12, color: AppColors.atlantico)` + texto `distance` (`AppColors.atlantico`, w700, 11). `SizedBox(height: 6)`.
    - **Nombre**: `restaurant.nombre`, `color: context.brand.textPrimary`, `fontWeight: FontWeight.w700`, `fontSize: 16`, `fontFamily: 'SF Pro Display'`, `maxLines: 1`, `overflow: ellipsis`.
    - **Subtítulo** `municipio` (si `isNotEmpty`): `color: context.brand.textSecondary`, 13, ellipsis. `SizedBox(height: 6)`.
    - **Fila estado + rating**: `OpenStatusBadge(horariosJson: restaurant.horariosJson, fallbackOpen: restaurant.open)`; si `restaurant.avgRating > 0` añadir (separado por `Spacer()` o `SizedBox`) `Icon(Icons.star_rounded, size: 14, color: AppColors.sol)` + texto `restaurant.avgRating.toStringAsFixed(1).replaceAll('.', ',')` en `context.brand.textPrimary`, w700, 13. Si `avgRating <= 0`, **no** pintar estrella ni texto (sin "n/d").
  - Padding interno cómodo (p.ej. derecha 12, vertical 8).
- Imports del card nuevo: `flutter/material.dart`, `app_colors.dart`, `brand_colors.dart`, `data/model/restaurant.dart`, `open_status_badge.dart`, `restaurant_detail/restaurant_detail_screen.dart`. **NO** importar `globalMethods.dart` ni `details/details.dart`.

**B. `cerca_ahora_screen.dart`**:
- Reemplazar `import '.../nearby_restaurant_card.dart';` por `import '.../cerca_ahora_list_card.dart';`.
- En el `itemBuilder`, sustituir `NearbyRestaurantCard(restaurant: entry.restaurant, distance: distStr)` por `CercaAhoraListCard(restaurant: entry.restaurant, distance: distStr)`. **No** cambiar nada más de la pantalla (header, empty states, skeleton, Semantics `cerca-ahora-list`, RefreshIndicator, lógica de distancia/fetch).

---

NO MODIFICAR / NO ROMPER:
- `NearbyRestaurantCard` (home horizontal) — intacto.
- La lógica de `cerca_ahora_screen.dart` (fetch, `_computeFiltered`, empty/skeleton/location states, Semantics anchors, header "X restaurantes abiertos a menos de N km") — intacta salvo el swap del card.
- Cubits, presenter, modelo, `pubspec.yaml`, `ios/`, `android/`, `main.dart`.

PROHIBIDO (rechazo automático del Evaluator):
- Que el card nuevo use `GlobalMethods.*` (bgColor/bgColorFilter/blueColor) o `Colors.white`/`Colors.white54`/`Colors.white10` hardcodeados para fondo/texto.
- Navegar al `Details` legacy en vez de `RestaurantDetailScreen`.
- Placeholder oscuro (caja gris/negra) — debe ser claro con icono `brand.textMuted`.
- Dejar "n/d" textual cuando `avgRating <= 0`.
- Tocar `NearbyRestaurantCard`, `pubspec.yaml`/`ios/`/`android/`/`main.dart`, cubits/presenter. Tests de widget que monten la pantalla.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze lib/ui/components/cards/cerca_ahora_list_card.dart lib/ui/pages/cerca_abiertos/cerca_ahora_screen.dart`: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`).
- Confirmar por diff: card nuevo con tokens `context.brand.*` + `AppColors.atlantico`/`AppColors.sol`, navegación a `RestaurantDetailScreen`, placeholder claro, sin "n/d"; swap del import+uso en la pantalla; `NearbyRestaurantCard` sin cambios.
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente; NO son regresiones.

OUT OF SCOPE (mencionar en informe):
- Rediseñar también `NearbyRestaurantCard` (sección "Cerca de ti" del home) al tema nuevo: follow-up.
- Bugs de "caja gris" en Visitas/Home hero (carga de imágenes en release): investigación aparte.

ENTREGA:
1. Fichero nuevo `cerca_ahora_list_card.dart` + diff de `cerca_ahora_screen.dart`.
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando el rediseño del card.
