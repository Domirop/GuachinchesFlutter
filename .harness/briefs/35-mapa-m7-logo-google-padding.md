Pantalla **Mapa** (`lib/ui/pages/map/map_search.dart`). Sprint **M7 (de la serie M1…M13, uno por harness)**: **compliance del logo de Google + padding del mapa**. El SDK de Google Maps **exige** que el logo de Google y el enlace de términos/atribución permanezcan **visibles y sin obstruir** (Google Maps Platform ToS). Hoy el `GoogleMap` NO define `padding`, así que su logo (esquina inferior-izquierda) queda **tapado** por el carrusel inferior (`_FloatingCardCarousel`) y por el strip de modo coche (`_DriveNearbyStrip`). Solución: pasar un `padding` inferior dinámico al `GoogleMap` que empuje el logo (y los controles del mapa) por encima del overlay inferior. Beneficio extra: el centrado de cámara (`_animateToUser`) pasa a encuadrar al usuario **por encima** del carrusel (mejor UX). Cliente-puro. Verificación por **code-review + `flutter analyze`** + suite existente sin nuevos fallos. **NO tests de widget** que monten `MapSearch`. **Verificación visual del logo final = on-device** (fuera del harness; mencionar en informe).

Ficheros a tocar: **sólo** `lib/ui/pages/map/map_search.dart`.

---

CONTEXTO (verificado leyendo el código):

- El `GoogleMap` se construye en `Positioned.fill` (~líneas 770-796) **sin** parámetro `padding`. `google_maps_flutter` soporta `GoogleMap(padding: EdgeInsets ...)` para insetar logo/controles y el área lógica de cámara.
- Overlays inferiores (dentro del mismo `builder` que ya calcula `isDriving` y `_visibleRestaurants`):
  - **Modo coche:** `_DriveNearbyStrip` en `Positioned(bottom: 0)` — alto ≈ 200-210 px (card 116 + pills 44 + paddings/spacing).
  - **Normal con resultados:** `Positioned(bottom: 8)` con chip contador (~30) + carrusel (`SizedBox(height: 116)`) → ≈ 160-165 px desde el borde inferior.
  - **Normal sin resultados visibles:** no hay overlay inferior → el logo puede quedar en su posición por defecto.
- Las variables `isDriving` y `_visibleRestaurants` están disponibles en el scope del `builder` donde se monta el `GoogleMap`.

---

CONTRATO FUNCIONAL (sólo M7):

1. **Calcular un inset inferior** según el overlay visible y pasarlo al `GoogleMap`:
   ```dart
   final double mapBottomInset = isDriving
       ? 210
       : (_visibleRestaurants.isNotEmpty ? 165 : 0);
   ```
   (Definir esta variable en el `builder`, junto a donde ya se calculan `isDriving`/`sorted`/`_visibleRestaurants`, antes del `return Stack(...)`.)
2. **Pasar el padding al `GoogleMap`:**
   ```dart
   GoogleMap(
     ...
     padding: EdgeInsets.only(bottom: mapBottomInset),
     ...
   )
   ```
   Mantener el resto de parámetros del `GoogleMap` exactamente igual.

(Valores 210/165 son estimaciones razonables del alto de cada overlay; el objetivo es que el logo de Google quede **por encima** del overlay. Si el dev mide alturas exactas mejor, pero no es obligatorio afinar al pixel — basta con que el logo no quede tapado.)

---

NO MODIFICAR / NO ROMPER:
- El resto de parámetros del `GoogleMap` (`mapType`, `style`, `myLocationEnabled`, `onMapCreated`, `onCameraMove`, `onCameraIdle`, `markers`, `initialCameraPosition`).
- La lógica de cámara (`_animateToUser`, chase cam, tilt) — sólo cambia el encuadre por el padding (efecto deseado), NO tocar sus cuerpos.
- Los overlays inferiores (carrusel, drive strip), los FABs, el header/scrim de M6.
- M1-M6 — intactos.
- El modelo, backend, `RestaurantMapCubit`, presenter — NO cambiar firmas. `pubspec.yaml`, `ios/`, `android/`, `main.dart`.
- M7 **NO** toca: empty states (M8), distance pill '--' (M9), http client (M10), filtrado cliente (M11), pausa sensores (M12), marker n/d (M13).

PROHIBIDO (rechazo automático del Evaluator):
- Ocultar/recolocar el logo de Google manualmente (NO se puede tapar ni mover con un widget propio; la vía compliant es `padding` del `GoogleMap`).
- Un inset hardcodeado que NO dependa del overlay visible (debe ser 0 cuando no hay overlay, para no dejar banda muerta).
- Romper otros parámetros del `GoogleMap`. Tocar otros M's. Tests de widget que monten `MapSearch`. Tocar `pubspec.yaml`/`ios/`/`android/`/`main.dart`.

VERIFICACIÓN (Evaluator, code-review):
- `flutter analyze lib/ui/pages/map/map_search.dart`: sin nuevos warnings/errores (se permiten los `info` preexistentes de `withOpacity`).
- Confirmar por diff: el `GoogleMap` recibe `padding: EdgeInsets.only(bottom: mapBottomInset)` con `mapBottomInset` derivado de `isDriving`/`_visibleRestaurants` (0 cuando no hay overlay).
- Smoke: `flutter test` (suite existente) SIN nuevos fallos respecto al baseline. NOTA: tests de `listas`/`settings`/`login`/`visitas` y `widget_test.dart` YA fallan ANTES por infra preexistente; NO son regresiones.
- **On-device (fuera del harness):** confirmar que el logo de Google queda visible por encima del carrusel y del drive strip. Mencionar como verificación manual pendiente.

OUT OF SCOPE (mencionar en informe):
- Estado vacío/error cuando no hay resultados (hoy `mapBottomInset` cae a 0 y no hay overlay): el empty-state es **M8**.

ENTREGA:
1. Diff de `map_search.dart` (padding dinámico del GoogleMap).
2. `flutter analyze` sin nuevos issues.
3. `flutter test` sin nuevos fallos respecto al baseline.
4. Informe del Evaluator confirmando M7 (+ nota de verificación on-device del logo).

Diff objetivo ≤ 15 líneas.
