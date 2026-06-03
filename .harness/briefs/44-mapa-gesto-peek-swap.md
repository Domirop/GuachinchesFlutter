# 44 — Mapa: gesto peek con swap al tocar + card rica (pieza 1/3 del rediseño de mapa)

## Contexto

Pantalla: tab MAPA (`lib/ui/pages/map/map_search.dart`). El bottom sheet del mapa
muestra una fila de cards en un `PageView` horizontal (`_cardsPageController`,
`viewportFraction: 0.88`) sincronizada con el pin seleccionado del mapa.

Estado actual de la interacción:
- `_onMarkerTapped(markerId)` (≈línea 637): selecciona el restaurante y llama a
  `_cardsPageController.animateToPage(idx, ...)`.
- `_onCardPageChanged` (≈línea 978): al hacer swipe del PageView, actualiza la
  selección y mueve el mapa.

## Problema (UX)

Al **tocar un pin** lejano, `animateToPage` recorre **animadamente todas las
cards intermedias** hasta llegar a la seleccionada. La metáfora espacial
(deslizar de lado) no casa con "he tocado allí" → se siente raro y poco pulido.

Referencia (app Eater): **separan dos intenciones en dos gestos**:
- **Tocar un pin** = *swap* directo (cambia el foco al instante, sin recorrer
  cards).
- **Swipe en la hoja** = ir al restaurante **contiguo** (anterior/siguiente),
  que sí tiene sentido espacial.

## Objetivo de esta pieza (1/3)

1. **Tap = swap, no recorrido.** Al tocar un pin, la card del sheet debe pasar a
   ese restaurante **sin la animación de scroll a través de las cards
   intermedias**. Usar `jumpToPage` (salto directo) o un cross-fade del
   contenido. La cámara del mapa sí puede animar suavemente al pin (como ya
   hace), pero el PageView no debe "recorrer" la lista.
2. **Swipe = vecino (sin cambios de fondo).** Hacer swipe en el sheet debe
   seguir llevando al restaurante contiguo y moviendo la selección/mapa, igual
   que hoy. No romper este flujo.
3. **Card rica con nota junto al nombre.** La card del sheet debe mostrar la
   **valoración (★ nota) en la misma línea / justo al lado del nombre**, además
   de lo que ya muestra (estado abierto/cerrado y distancia). Reusar el patrón y
   componentes existentes (no duplicar cards); si encaja, alinear con el estilo
   de `SearchResultCard`.

## Restricciones (duras)

- **Modo coche INTACTO.** No tocar el `_DrivingDetector`, ni el flujo de
  `isDriving`, ni la cámara chase/tilt, ni el panel de conducción. Esta pieza es
  solo el gesto del sheet en modo normal y la card.
- No tocar `pubspec.yaml`, `ios/`, `android/`.
- No introducir catch silenciosos ni strings hardcodeadas que deberían venir de
  locale/config.
- Mantener/añadir selectores estables `Semantics(identifier: '<screen>-<comp>-<rol>')`
  en kebab-case inglés para la card del sheet (p.ej. `mapa-sheet-card`,
  `mapa-sheet-rating`).
- No duplicar componentes existentes (OpenStatusBadge, etc.).

## Criterios de aceptación sugeridos

- **ac-1** (ios, code-review): al tocar un pin, `_onMarkerTapped` deja de usar
  `animateToPage` para el recorrido; usa salto directo/cross-fade. `target`:
  tap no recorre cards intermedias.
- **ac-2** (ios, code-review): el swipe del PageView sigue actualizando
  selección + mapa (flujo `_onCardPageChanged` intacto). `target`: swipe = vecino.
- **ac-3** (ios, code-review): la card del sheet muestra ★nota junto al nombre,
  más estado abierto/cerrado y distancia, reusando componentes. `target`: nota
  inline con el nombre.
- **ac-4** (ios, code-review): modo coche sin cambios (diff no toca
  `_DrivingDetector`/`isDriving`/chase). `target`: driving intacto.

## Verificación

Principalmente **code-review** del diff: tocar un marker de Google Maps es una
platform view y **no** es testeable de forma fiable con Patrol; no exigir un test
de integración que toque pins. Si la card se extrae a un widget testeable de
forma aislada, un `flutter_test` de que renderiza nombre + ★nota es bienvenido,
pero opcional.

## Nota sobre el contrato (para el Planner)

- En `acceptance_criteria[].measurable_by` usar **`code-review`** para ac-1..ac-4
  (la lógica del gesto y el diff del modo coche se verifican leyendo el diff).
  Opcionalmente, si se añade el widget test de la card, ese criterio puede ir con
  `measurable_by: flutter_test`.
- En `test_plan.ios.tooling` **NO** existe el valor "code-review" (solo
  `xcodebuildmcp | patrol | maestro | flutter_test | simctl`). Poner
  **`flutter_test`** como tooling (para el widget test opcional de la card). Si no
  hay test de integración, deja `flutter_test_paths` vacío o con el test de la card.
- `backend_review` = false (cambio solo de UI cliente).

## Fuera de alcance (siguientes piezas)

- Pieza 2: pin seleccionado = teardrop + nota (en vez de pastilla escalada).
- Pieza 3: pins con nombre (label) + dot de estado y decluttering.
