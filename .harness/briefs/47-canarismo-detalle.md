# 47 — Canarismo del día: pantalla de detalle (diseño cuidado, no vacía)

## Contexto

Ya existe la feature "Canarismo del día" en el home:
- Datos: `lib/data/canarismos.dart` — modelo `Canarismo(palabra, significado)`,
  lista `kCanarismos` (365 voces/expresiones), `canarismoOfDay([now])`
  (determinista por fecha) y `canarismoRandom(seed, {actual})` (otra al azar
  distinta).
- Card teaser en el feed: `lib/ui/components/canarismo_card.dart`
  (`CanarismoCard`), colocada entre la sección "today" y "Cerca de ti" en
  `new_home_body.dart`. Hoy muestra la palabra **entrecomillada** + chevron y un
  desplegable inline con el significado + botón Compartir.

El modelo NO tiene ejemplo de uso (las 365 voces son palabra + significado).

## Objetivo

Crear una **pantalla de detalle del canarismo** bien diseñada y hacer que la
card la abra al tocar. Como solo hay palabra + significado, el reto es de diseño:
**que no se sienta vacía** — hay que llenarla con jerarquía tipográfica, un
motivo decorativo de marca y acciones que inviten a explorar.

### 1. Pantalla `CanarismoDetailScreen`

Nueva pantalla (`lib/ui/pages/canarismo/canarismo_detail_screen.dart`), full
screen, fondo `context.brand.base`. Recibe un `Canarismo` inicial. Diseño
sugerido (eres senior de producto, cuídalo):

- **Cabecera**: chevron de volver (`arrow_back_ios_new_rounded`) + eyebrow
  `CANARISMO DEL DÍA` en atlántico (`AppTextStyles.eyebrow`).
- **Bloque protagonista** (lo que evita el vacío): la **palabra ENTRECOMILLADA**
  muy grande (`AppTextStyles.displayHero`, ~36–44), centrada o alineada, con un
  **motivo decorativo** detrás/al lado: o bien la **inicial gigante** de la
  palabra a muy baja opacidad como marca de agua, o un par de **comillas
  tipográficas grandes** (« »/“ ”) en atlántico translúcido. Que respire y se
  sienta editorial, no un texto suelto en una pantalla en blanco.
- **Significado**: debajo, tamaño legible (15–16, `AppTextStyles.ui` o
  `editorial`), con buen interlineado y márgenes.
- **Acciones**:
  - **Compartir** (primario, pill atlántico) — comparte texto:
    `"palabra" — significado` + `vía Dónde Comer Canarias` (usar `share_plus`,
    ya está en el proyecto). *(La imagen branded para Stories es una fase
    posterior; aquí texto.)*
  - **Otra palabra** (secundario) — muestra otra voz al azar con
    `canarismoRandom(seed, actual: actual)` y refresca la pantalla (pantalla
    stateful). Esto mantiene viva la pantalla e invita a explorar las 365.
- **Pie**: una línea sutil de identidad, p.ej. `Diccionario del habla canaria ·
  Dónde Comer Canarias` en `AppTextStyles.muted`.

### 2. La card abre el detalle

`CanarismoCard`: al tocar la card (o un "ver" claro), **navegar** a
`CanarismoDetailScreen` con `canarismoOfDay()` (Navigator.push +
MaterialPageRoute). Puede **sustituir** el desplegable inline actual por esta
navegación (es más limpio: teaser en el feed → detalle al tocar). Mantener la
palabra **entrecomillada** en el teaser.

## Restricciones (duras)

- Reusar el sistema de marca: `AppColors`, `AppTextStyles`, `context.brand.*`.
  NADA de colores/tamaños sueltos fuera del design system.
- No tocar `pubspec.yaml`, `ios/`, `android/`. No catch silenciosos.
- Selectores estables `Semantics(identifier: '<screen>-<comp>-<rol>')` en
  kebab-case inglés: p.ej. `canarismo-detail-screen`, `canarismo-detail-word`,
  `canarismo-detail-share`, `canarismo-detail-shuffle`, `canarismo-detail-back`.
- No duplicar componentes; reusar los existentes donde aplique.
- Esta feature es **culturalmente en español** (palabras canarias). Las pocas
  etiquetas de UI ("Compartir", "Otra palabra", "Canarismo del día") pueden ir
  **hardcodeadas en español** — NO son contenido localizable, son parte del
  concepto. (El contenido de `kCanarismos` es dato, no copy.)
- `canarismoOfDay` / `canarismoRandom` ya son funciones puras: NO reescribirlas.

## Criterios de aceptación sugeridos

- **ac-1** (ios, code-review): existe `CanarismoDetailScreen` con la palabra
  entrecomillada en grande + motivo decorativo (inicial watermark o comillas) +
  significado + acciones, fondo de marca. `target`: pantalla rica, no vacía.
- **ac-2** (ios, code-review): "Otra palabra" usa `canarismoRandom` y refresca
  la pantalla a otra voz distinta. `target`: explorable.
- **ac-3** (ios, code-review): "Compartir" usa `share_plus` con la palabra
  entrecomillada + significado + firma de marca. `target`: compartible.
- **ac-4** (ios, code-review): `CanarismoCard` abre `CanarismoDetailScreen` al
  tocar; la palabra va entrecomillada en el teaser. `target`: navegación.
- **ac-5** (ios, flutter_test, opcional): test de `canarismoRandom` (devuelve una
  voz válida y, con `actual`, distinta de la actual).

## Verificación

Principalmente **code-review** del diff (la pantalla es UI sobre platform-neutral
widgets; no requiere Patrol). `test_plan.ios.tooling` = `flutter_test`
(para ac-5). `backend_review` = false.

## Fuera de alcance (fase posterior)

- Imagen branded para compartir en Stories (9:16) con logo DCC.
- Histórico de canarismos en Perfil.
- Mover el corpus a Remote Config / backend.
