# 45 — Mapa: pin seleccionado = teardrop con nota (pieza 2/3 del rediseño de mapa)

## Contexto

Pantalla: tab MAPA (`lib/ui/pages/map/map_search.dart`). Los markers se pintan a
canvas como bitmaps (`_buildBubbleMarker`, `_buildDotBitmap`). Hoy:
- No seleccionado (zoom alto): pastilla oscura `#1B1D22` con dot de estado +
  nota (estilo TheFork). Zoom bajo: dot verde/rojo.
- **Seleccionado**: la **misma pastilla pero escalada** (scale 4.2) en color
  `AppColors.atlantico`, con borde blanco + halo. Anclada en `(0.5, 1.0)`.

## Problema (UX)

El estado seleccionado es "lo mismo pero más grande": solo cambia de tamaño, no
de **forma**. Se lee poco como "esto está seleccionado". Referencia (Apple Maps /
Eater): el pin seleccionado es un **teardrop** (cabeza redonda + punta inferior)
claramente distinto de los puntos del resto → salto de jerarquía inmediato.

## Objetivo de esta pieza (2/3)

Cambiar **solo el marker SELECCIONADO** a una forma de **teardrop / pin de mapa**:

1. **Forma teardrop**: cabeza circular (o redondeada) arriba + punta hacia abajo,
   con la **punta anclada exactamente en las coordenadas del restaurante**
   (anchor `(0.5, 1.0)`, la punta en el borde inferior del bitmap).
2. **Nota dentro de la cabeza**: si `avgRating > 0`, mostrar la nota (★ o número)
   dentro de la cabeza del teardrop. Si no hay nota, teardrop liso (sin texto) o
   un punto/sello neutro. ("teardrop + nota").
3. **Color y realce**: relleno `AppColors.atlantico` (color de foco/selección),
   borde blanco grueso + sombra/halo para que destaque sobre el mapa crema.
   El estado abierto/cerrado del seleccionado se comunica en la **card** del
   sheet (status line), no hace falta recodificarlo en el color del teardrop.
4. **Markers NO seleccionados: sin cambios** en esta pieza (siguen como pastilla
   /dot). Los nombres (labels) son la pieza 3.

## Restricciones (duras)

- **Modo coche INTACTO.** No tocar `_DrivingDetector`, `isDriving`, cámara
  chase/tilt ni panel de conducción.
- El cache de markers (`_markerCache`, `_markerKey`) debe seguir funcionando: la
  clave ya distingue `selected` (`'${r.id}_${open}_${selected}'`), así que el
  teardrop seleccionado y la pastilla no-seleccionada se cachean por separado.
  Mantener anchors correctos al alternar (el seleccionado en `(0.5,1.0)`).
- No romper el swap del tap (pieza 1) ni el swipe a vecinos.
- No tocar `pubspec.yaml`, `ios/`, `android/`. No catch silenciosos. No strings
  hardcodeadas que deban venir de locale/config.
- No duplicar componentes; reutilizar helpers de pintura existentes donde aplique.

## Criterios de aceptación sugeridos

- **ac-1** (ios, code-review): el marker seleccionado se pinta como teardrop
  (cabeza + punta) con la punta anclada en las coords `(0.5, 1.0)`. `target`:
  forma de pin, no pastilla escalada.
- **ac-2** (ios, code-review): si `avgRating > 0`, la nota aparece dentro de la
  cabeza del teardrop; si no, teardrop sin texto. `target`: teardrop + nota.
- **ac-3** (ios, code-review): markers no seleccionados sin cambios; modo coche
  sin cambios en el diff. `target`: alcance acotado.

## Verificación

**code-review** del diff (pintura a canvas + ensamblado del marker). No es
testeable con Patrol (platform view de Google Maps). `test_plan.ios.tooling` =
`flutter_test` (sin tests de integración; `flutter_test_paths` puede ir vacío).
`backend_review` = false.

## Fuera de alcance (pieza 3)

- Pins NO seleccionados con **nombre** (label) + dot de estado y decluttering de
  labels por zoom/solape.
