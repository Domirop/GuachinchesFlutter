# 46 — Mapa: pins con nombre (label) + dot de estado y decluttering (pieza 3/3)

## Contexto

Pantalla: tab MAPA (`lib/ui/pages/map/map_search.dart`). Markers pintados a canvas
como bitmaps. Tras piezas 1 y 2:
- Seleccionado: **teardrop** con nota (pieza 2). NO se toca.
- No seleccionado (zoom alto): pastilla oscura con dot + nota (estilo TheFork).
  Zoom bajo: dot verde/rojo (`_buildDotBitmap`). El gate dot↔pastilla es
  `_kBubbleZoomThreshold` (`_currentZoom`, `_onCameraMove`).

## Problema (UX)

La pastilla de **nota** ("4.8") no deja escanear el mapa: no sabes *qué* sitio es
sin tocar. Referencia (Eater): el pin no seleccionado es **dot de estado +
NOMBRE** → el mapa se lee como un índice. Pero Eater **declutteriza**: no muestra
todos los nombres a la vez (los racimos densos quedan como puntos sin label).

## Objetivo de esta pieza (3/3)

Cambiar el marker **NO seleccionado** de "pastilla de nota" a **dot de estado +
NOMBRE**, con decluttering:

1. **Dot de estado + nombre**: un dot pequeño verde/rojo (abierto/cerrado, mismos
   colores que hoy) en las coordenadas, y el **nombre del restaurante** como label
   a la derecha del dot. El nombre en color tinta DCC (`context.brand.textPrimary`
   o `AppColors.ink`) con **halo/contorno blanco** para legibilidad sobre el mapa
   crema. Anclar el bitmap para que el **dot caiga en las coords** (el nombre se
   extiende a un lado; ajustar anchor en consecuencia).
2. **Sin nota en el pin no seleccionado**: la nota ya vive en el teardrop
   seleccionado (pieza 2) y en la card del sheet. Aquí: nombre + estado, no nota.
3. **Decluttering (pragmático, sin colisiones por proyección a pantalla)**:
   - **Labels solo por encima de un umbral de zoom** (reutilizar/añadir un
     `_kLabelZoomThreshold`; por debajo → solo dots de estado, sin nombre). Esto
     ya reduce el grueso del solape.
     - Opción válida: el umbral de label puede ser igual o mayor que
       `_kBubbleZoomThreshold`.
   - **Cap por viewport**: mostrar nombre solo para los restaurantes visibles en
     el viewport (ya se trackean en `_visibleRestaurants`) y, si superan un máximo
     razonable (p.ej. 24), mostrar dots en vez de labels para el resto. **No
     truncar en silencio**: si se capa, dejar un `debugPrint`/log de cuántos se
     omitieron (regla anti "parece que está todo").
4. **Seleccionado (teardrop) intacto.** El seleccionado siempre muestra su
   teardrop con nota, aunque el zoom esté por debajo del umbral de labels.

## Restricciones (duras)

- **Modo coche INTACTO.** No tocar `_DrivingDetector`, `isDriving`, cámara
  chase/tilt ni panel de conducción. En modo coche, además, **no** mostrar labels
  (mantener dots/teardrop) para no recargar la pantalla mientras se conduce.
- Mantener el cache de markers (`_markerCache`/`_markerKey`). La clave debe
  distinguir el modo de render (dot vs label vs teardrop) para no servir bitmaps
  obsoletos; ampliar la clave si hace falta (sin romper el cache existente).
- Reconstruir markers en `_onCameraMove` solo cuando cruza el umbral relevante
  (como ya hace con dot↔bubble), no en cada frame, para no matar performance.
- No tocar `pubspec.yaml`, `ios/`, `android/`. No catch silenciosos. Nada de
  strings de UI hardcodeadas que deban venir de locale (el nombre del restaurante
  viene del modelo, eso es dato, no copy).
- No duplicar; reutilizar helpers de pintura/`TextPainter` existentes.

## Criterios de aceptación sugeridos

- **ac-1** (ios, code-review): el marker no seleccionado por encima del umbral de
  zoom se pinta como **dot de estado + nombre** con halo blanco; el dot cae en las
  coords (anchor correcto). `target`: pin con nombre.
- **ac-2** (ios, code-review): por debajo del umbral, o en modo coche, o al
  superar el cap del viewport → **solo dots** (sin label); el cap se loguea.
  `target`: decluttering por zoom + cap, sin truncado silencioso.
- **ac-3** (ios, code-review): no se pinta nota en el pin no seleccionado;
  abierto/cerrado se mantiene como color del dot. `target`: nombre + estado, sin
  nota.
- **ac-4** (ios, code-review): teardrop seleccionado (pieza 2), swap/swipe
  (pieza 1) y modo coche sin regresiones en el diff. `target`: alcance acotado.
- **ac-5** (ios, flutter_test, opcional): la **decisión de decluttering**
  (mostrar label vs dot, dado zoom / nº visibles / driving) se extrae a una
  función/helper pura y se cubre con un `flutter_test`.

## Verificación

**code-review** del diff (pintura del label con halo, anchor, gating de zoom/cap,
exclusión en modo coche). La decisión de decluttering, si se extrae a helper puro,
es testeable con **`flutter_test`** (ac-5). `test_plan.ios.tooling` =
`flutter_test`. No Patrol (platform view). `backend_review` = false.
