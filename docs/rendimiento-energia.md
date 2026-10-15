# Rendimiento y energía: por qué se calienta la app

Rama `perf/energia`, rebasada sobre `feature/rediseno-ios27` (`874bdab`). Medición inicial sobre `66936bb`; segunda tanda sobre `874bdab` (ver «Tras el rebase»). Fecha: 15-10-2026.

## Resumen

La app **casi nunca deja de dibujar**. Con el Inicio abierto y sin tocar nada,
el motor pintaba la pantalla completa de forma continua (67 fotogramas por
segundo en el simulador, a 60 Hz; en un iPhone ProMotion son hasta 120 por
segundo), incluidos 4–5 desenfoques de cristal (`BackdropFilter`) por
fotograma. Lo provocaban animaciones en bucle que no se paraban nunca:

1. **Un spinner escondido.** La pestaña Mapa, mientras no se abre, muestra un
   `CircularProgressIndicator` (`map_search.dart:1109`). El `IndexedStack`
   mantiene las cinco pestañas montadas y solo Explora iba bajo `TickerMode`,
   así que ese spinner giraba sin verse y **mantenía toda la app redibujando
   hasta que el usuario abría el mapa por primera vez**.
2. **Bucles fuera de pantalla.** La onda del punto «abierto» (`GmLiveDot`), el
   borde de nubes (`GmCloudEdge`) y las nubes/lluvia del hero seguían
   animando aunque se hubiera hecho scroll y no se vieran.
3. **Trabajo por fotograma muy caro.** Cada nube del hero eran ~15 formas con
   `MaskFilter.blur` repintadas en cada fotograma (Impeller no tiene caché de
   raster), y el cielo de estrellas hacía `setState` 120 veces por segundo
   sin cambiar nada en pantalla.
4. **A 120 Hz.** `CADisableMinimumFrameDurationOnPhone` está activado, así que
   en ProMotion cada animación cuesta el doble que a 60 Hz.

A eso se suman el GPS (el punto azul del mapa encendido en cualquier pestaña
una vez abierto el mapa), la red (cada acierto de caché volvía a pedir los
datos) y el *session replay* de PostHog, que cada 2 s captura la pantalla
entera y, con la pantalla siempre en movimiento, nunca se ahorraba una subida.

**Resultado medido** (simulador; detalle en [Mediciones](#mediciones)):
con esta rama, las pantallas que no se ven o que se han bajado dejan de
dibujar (Inicio bajado 67 → 18 fps; Listas antes de abrir el mapa
67 → 0,6 fps; lista temática bajada 67 → 0,5 fps) y el Inicio arriba gasta
~20 % menos CPU. Lo que más consume ahora es el *session replay* de PostHog
(hasta ~45 % de la CPU con la pantalla en movimiento) y los bucles que están
a la vista.

Los arreglos de esta rama no cambian nada visible. Las medidas de más
impacto que quedan sí cambian algo visible o son decisiones de producto, y
están en [Propuestas pendientes de decisión](#propuestas-pendientes-de-decisión).

## Metodología

### Qué se mide y por qué

El calor sale de CPU, GPU, radio y GPS trabajando sin descanso. En Flutter,
la CPU y la GPU trabajan **en cada fotograma**, y un fotograma se dibuja solo
si algo lo pide (un `Ticker`, un `setState`, un repintado). Por eso la
métrica principal es independiente del hardware:

- **Fotogramas por segundo que pide la app en reposo.** Una pantalla quieta
  debería estar en ~0. Cada fotograma es build + layout + paint en la CPU y
  la composición completa en la GPU (con Impeller no hay repintado parcial ni
  caché de raster).
- **Tickers activos por widget**: quién pide esos fotogramas.
- **Capas caras del fotograma**: `BackdropFilter` (desenfoques que se
  recalculan enteros en cada fotograma), `Opacity`, vistas de plataforma.
- **CPU del proceso** durante cada ventana (tiempo de CPU acumulado del
  proceso, medido cada segundo desde macOS).

### Herramienta: censo de energía

`integration_test/perf/energy_census_test.dart` recorre la app real
(arranque normal, datos reales de la API, Tenerife) y en cada escenario mide
una ventana de 10 s en reposo o durante un scroll:

| Escenario | Qué hace |
|---|---|
| `inicio_reposo_arriba` | Inicio sin tocar, arriba del todo |
| `inicio_scroll` | 4 flings hacia abajo |
| `inicio_reposo_scrolleado` | Inicio quieto tras bajar |
| `tab_listas/mapa/visitas/perfil_reposo` | Cada pestaña, quieta |
| `lista_tradicional_*` | «Guachinches tradicionales» (cabecera animada «mesa con brindis»): reposo, scroll y reposo tras bajar |
| `ficha_reposo` / `ficha_scroll` | Ficha de la primera tarjeta del Inicio |
| `encuesta_entrada_reposo` / `encuesta_ranking_reposo` | Premios: Entrada (papeleta y barrica) y Ranking (brillos) |
| `visita_reels` | Primera visita de la pestaña Visitas (vídeo) |

Detalles de la medición:

- En un test «vivo» el binding de test encadena un fotograma tras otro aunque
  nadie los pida. El censo usa un binding propio que **solo cuenta los
  fotogramas pedidos por la app** (`scheduleFrame()`), que es lo que, fuera
  del test, despierta al motor.
- Ejecución: `flutter drive` (no `flutter test`, que no deja usar un binding
  propio) con `test_driver/perf_driver.dart`; el informe JSON queda en
  `build/perf/energy_census.json`.
- Antes y después se miden **con el mismo arnés, el mismo simulador y la
  misma API**; solo cambia `lib/`.

### Dónde se ha medido y límites

- **Simulador iPhone 17 Pro Max (iOS 26.2), modo debug.** El iPhone 15 Pro
  Max del propietario estaba bloqueado y sin cable durante la sesión, así que
  no se pudo usar `flutter run --profile` en el dispositivo (la build profile
  sí se compiló). En el simulador:
  - los **fotogramas pedidos, los tickers y las capas** son fiables: dependen
    del código, no del hardware;
  - la **CPU** es la del Mac y en modo debug (JIT): sirve para comparar antes y
    después, no como valor absoluto del iPhone;
  - el simulador va a 60 Hz: **en un iPhone ProMotion los fotogramas
    continuos son hasta el doble**;
  - no hay tiempos de build/raster fiables (solo en profile) ni temperatura.
- `env_files/debug.env` es el que carga el modo debug/profile: lleva
  `ENABLE_NEW_HOME=true`, la campaña de Premios forzada y la clave de PostHog
  (el *session replay* está activo en la medición, como en producción).
- El tiempo en la zona era «nublado», así que el hero del Inicio llevaba la
  capa de nubes, como verá un usuario del norte de Tenerife buena parte del
  año.

### Cómo repetirlo en el iPhone (profile)

Con el iPhone desbloqueado y **conectado por cable** (por wifi el VM Service
necesita aceptar «Red local» en el móvil):

```bash
flutter drive --profile -d <udid> --driver=test_driver/perf_driver.dart --target=integration_test/perf/energy_census_test.dart
```

El JSON trae además `build_ms` y `raster_ms` por escenario (media, p90, p99,
máximo). En paralelo, con Instruments:

```bash
xcrun xctrace record --device <udid> --template 'Power Profiler' --attach Runner --time-limit 60s --output inicio.trace
```

Para el estado térmico, el *Thermal State* de Instruments o
`ProcessInfo.thermalState` desde la app. Para Android:
`adb shell dumpsys gfxinfo com.jonay.guachinches framestats` y
`adb shell dumpsys batterystats --charged com.jonay.guachinches`.

**Compilar iOS con Flutter 3.47**: `google_mobile_ads` (CocoaPods) choca con
SPM. Para compilar hay que poner temporalmente en `pubspec.yaml`
`flutter: config: enable-swift-package-manager: false` (no se commitea).

## Mediciones

Simulador iPhone 17 Pro Max (60 Hz), modo debug, API real, Tenerife,
tiempo nublado. «Antes» = `66936bb`; «después» = esta rama; «sin PostHog» =
esta rama con la clave de PostHog vacía (solo para medir; no se commitea).
Ventanas de 10 s.

- **fps** = fotogramas por segundo que pide la app. Con 60–73 la pantalla se
  redibuja sin parar (el simulador va a 60 Hz; los escenarios con scroll
  incluyen los fotogramas del gesto). En un iPhone ProMotion, el mismo bucle
  pide hasta **120**.
- **CPU** = tiempo de CPU del proceso / duración de la ventana, en el Mac y en
  JIT. Sirve para comparar columnas, no como valor del iPhone. Ruido medido
  entre ejecuciones: **±5–10 puntos** (las pestañas en reposo, que no
  cambian, oscilan entre 11 y 16 %).
- **Blur** = `BackdropFilter` en el último fotograma.
- Lista y ficha se midieron en pasadas aparte (`PERF_ONLY=lista|ficha`) con
  el arnés ya corregido; en la pasada completa la lista no llegaba a
  desplazarse y la ficha no se abría.



### Lectura

- **Lo que deja de dibujar sin verse** (arreglado): con el Inicio bajado
  (67 → 18 fps), cualquier pestaña antes de abrir el mapa (Listas: 67 →
  0,6 fps) y la lista temática bajada (67 → 0,5 fps). Son los casos más
  comunes de «la app abierta sin tocarla».
- **Lo que sigue dibujando** son bucles **a la vista**: el Inicio arriba
  (nubes del hero, borde de nubes y onda del punto «abierto» de «Hoy»), la
  ficha de un sitio abierto (onda del punto), la cabecera de las listas y la
  Entrada de la encuesta (borde de nubes). Pararlos cambia algo visible:
  propuesta 3.
- **Las nubes** pintadas una vez bajan la CPU del Inicio arriba de 54 a 44 %
  aunque sigan moviéndose.
- **PostHog** es el mayor coste que queda cuando la pantalla se mueve: sin
  él, el Inicio arriba baja de 44 a 27 %, el scroll del Inicio de 75 a 41 %,
  la Entrada de la encuesta de 44 a 22 % y los Reels de 34 a 22 %. En
  reposo real (0,5 fps) apenas cambia (10–13 %): el replay solo trabaja de
  verdad cuando la pantalla cambia. Ojo: en debug el hash que PostHog
  calcula en Dart es más lento que en release, así que en el iPhone la
  diferencia será menor; la lectura de la pantalla desde la GPU y el PNG no
  dependen del modo.
- **Reels**: 12 fps es el ritmo del vídeo en el simulador; no hay tickers.
- Con 120 Hz (iPhone 15 Pro Max), cada fila con 67 fps aquí es **hasta el
  doble** de trabajo de GPU allí: propuesta 1.

## Tras el rebase sobre `874bdab`

`feature/rediseno-ios27` avanzó mientras tanto (`874bdab`: rediseño de listas,
login, quiz, mapa, descubrir…). La rama se ha rebasado encima; el único
conflicto real fue `map_search.dart`, reescrito en `fd99f86`: el mapa nuevo
mantenía los mismos problemas de GPS (punto azul en cualquier pestaña, flujo
de alta precisión con otra ruta encima o en segundo plano, `.timeout`) y el
arreglo se ha vuelto a aplicar sobre él.

Segunda tanda, mismo simulador y arnés (fps pedidos por la app; la CPU de
esta tanda no se usa: el Mac estaba cargado por otras sesiones y el reposo
de Perfil marcó 20 % en una pasada y 8 % en otra):



- **Se mantiene la mejora** donde importa: Inicio bajado 67 → 18 fps y lista
  temática bajada 67 → 0,6 fps.
- En `874bdab` el mapa nuevo ya no deja un spinner girando escondido
  (Listas 0,7 fps también sin la rama); `TickerMode` en todas las pestañas
  sigue cubriendo cualquier otro bucle de una pestaña oculta.
- **Ficha y Reels no se pudieron repetir** sobre `874bdab`: durante esas
  pasadas `GET /video-ingestion/restaurant-videos/published` dejó de
  responder (más de 30 s también con `curl`) y el Inicio se quedaba en
  esqueletos, **igual con `874bdab` sin cambios** (control). Valen las cifras
  de la primera tanda.

### Hallazgos del QA en Android (Pixel 9 Pro, `d533a2e`)

| QA | Qué es | En esta rama |
|---|---|---|
| I1 | ~60 fps continuos en reposo hasta abrir Mapa (24 % de un núcleo en Perfil): el spinner «Preparando el mapa…» girando oculto | Cubierto: `TickerMode` en las cinco pestañas (y `874bdab` ya no lo tiene). |
| I2 | Nubes del hero animando con el Inicio desplazado y tiempo nublado (36–41 % de CPU) | Cubierto: pausa con el hero fuera de la vista, y cada nube se pinta una vez (sin ~90 pasadas de desenfoque por fotograma). Con el hero visible siguen moviéndose (propuesta 3). |
| I3 | Tirones al estirar en la cima del Inicio (18–28 % de fotogramas lentos; 93 % con varios *pull-to-refresh*) | En parte. Al estirar, `ParallaxHeroSlot` cambia el **alto** del hero en cada fotograma, que se vuelve a maquetar y pintar entero (sombras de texto con blur 16, chip de cristal σ18, capa de tiempo); en el scroll normal solo cambia `top` y no se repinta. Las nubes ya no cuestan ~90 desenfoques por fotograma. El arreglo estructural (hero de alto fijo y estirar solo la foto con un `Transform`) cambia cómo se ve el estirado: propuesta 7, a medir en dispositivo. |
| Reels | Picos de 350–500 ms al cambiar de vídeo | Sin medir en dispositivo real (el emulador decodifica por software). |

### Robustez de la caché

Al revisar el rebase apareció un riesgo del umbral de revalidación: los
`fetchBody` guardaban en caché **cualquier** respuesta, también un 502; antes
la revalidación de cada acierto lo curaba en la siguiente petición, con el
umbral se habría servido minutos. Ahora una respuesta que no es 2xx no se
guarda y una entrada ilegible se ignora y se va a la red (commit
`fix(red): no cachear respuestas de error…`, con dos tests).

## Hallazgos priorizados

Impacto: energía y calor (alto / medio / bajo). Esfuerzo: S (horas), M (un
día), L (varios días). Las líneas son del commit base `66936bb`.

| # | Hallazgo | Evidencia | Fichero:línea | Impacto | Esfuerzo | Estado |
|---|---|---|---|---|---|---|
| 1 | Las pestañas ocultas seguían animando: solo Explora iba bajo `TickerMode`. El spinner del placeholder de Mapa giraba escondido y mantenía la app dibujando sin parar hasta abrir el mapa | Censo: `CircularProgressIndicator` activo en Inicio y Listas sin verse; Listas a 67 fps en reposo | `new_home_tab_scaffold.dart:126`, `map_search.dart:1109` | Alto | S | **Arreglado** |
| 2 | Bucles infinitos que no se paran fuera de pantalla: onda del punto «abierto» (`GmLiveDot`), borde de nubes (`GmCloudEdge`) en listas y encuesta; dentro de un `SliverToBoxAdapter` siguen montados | Censo: 1–3 `GmLoop` activos con el Inicio y la lista bajados | `gm_motion.dart:208`, `gm_widgets.dart:730`, `today_grid_section.dart:84`, `advanced_search.dart:1387` | Alto | S | **Arreglado** |
| 3 | Nubes del hero: ~15 formas con `MaskFilter.blur` (σ 7–22) por nube y fotograma; sin caché de raster en Impeller | Censo: `CloudsOverlay` activo en todo el Inicio, también con el hero fuera de la vista | `clouds_overlay.dart:33`, `:157-163` | Alto | M | **Arreglado** (se rasteriza una vez; pausa fuera de la vista) |
| 4 | Cielo de estrellas: `setState` en cada vsync de 19 a 7 h sin efecto visible (`shouldRepaint` solo compara la opacidad) | Código | `starfield_painter.dart:76` | Alto (de noche) | S | **Arreglado** |
| 5 | 120 Hz en ProMotion (`CADisableMinimumFrameDurationOnPhone`): todo fotograma continuo cuesta el doble | `Info.plist` | `ios/Runner/Info.plist:7` | Alto | S | **Propuesta** (visible) |
| 6 | *Session replay* de PostHog: cada 2 s recorre el árbol, lee la pantalla de la GPU, calcula un hash byte a byte en el hilo de UI y, si cambió, codifica y sube un PNG. Con la pantalla siempre animada, cambia siempre | Ver «Mediciones» (con y sin PostHog) | `posthog_analytics_service.dart:29-34`, `main.dart:319` | Alto | S | **Propuesta** (producto) |
| 7 | GPS del mapa: el punto azul nativo (`myLocationEnabled: true`) seguía activo en cualquier pestaña tras abrir el mapa; el stream de alta precisión (5 m) seguía con la ficha abierta encima y en segundo plano | Código | `map_search.dart:1163`, `:335` | Alto | S | **Arreglado** |
| 8 | Caché HTTP: cada acierto lanzaba igualmente la petición y reescribía SQLite; con Inicio y Mapa pidiendo las ~23 páginas de restaurantes de la isla, un arranque con caché llena son ~46 peticiones | Test `(d)` | `HttpRemoteRepository.dart:89` | Medio-alto | S | **Arreglado** (listas: revalida si > 5 min; referencia: > 30 min; fichas: siempre) |
| 9 | La pestaña Mapa descarga toda la isla en serie al arrancar, aunque no se abra (duplica la carga del Inicio) | Código | `map_search.dart:133-136` | Medio | M | **Propuesta** (primera apertura del mapa más lenta) |
| 10 | Lecturas de GPS con `Future.timeout`: el futuro falla pero el GPS sigue buscando; se relanza en cada vuelta a primer plano | Código | `location_cubit.dart:154`, `:166` | Medio | S | **Arreglado** (`timeLimit`) |
| 11 | Borde de nubes: `RepaintBoundary` fuera del desplazamiento, el SVG se volvía a grabar en cada fotograma | Código | `gm_home_extras.dart:56` | Bajo-medio | S | **Arreglado** |
| 12 | Desenfoques tapados por degradados casi opacos: barra de pestañas sobre un fundido al 94 %, velo superior del Ranking al 96 %, barra inferior de Premios | Censo: 4–5 `BackdropFilter` por fotograma en el Inicio | `new_home_tab_scaffold.dart:353`, `premios_ranking_page.dart:450`, `premios_widgets.dart:521` | Medio | S | **Propuesta** (visible, muy poco) |
| 13 | Mapa: `_rebuildMarkers` dentro de `build`; cada fix de GPS (5 m) o cada bitmap de marcador terminado rehace todos los marcadores de la isla | Código | `map_search.dart:1140` | Medio (con el mapa abierto) | M | Recomendación |
| 14 | Mapa de la ficha con `liteModeEnabled`: solo existe en Android; en iOS es un mapa nativo completo dentro del scroll | Código | `ficha_sections.dart:545` | Medio (en la ficha) | M | Recomendación (imagen estática) |
| 15 | AdMob se inicializa en cada arranque aunque el rediseño no muestra anuncios | Código | `main.dart:103` | Medio-bajo | S | **Propuesta** (negocio) |
| 16 | `jsonDecode` de las páginas de restaurantes en el hilo de UI | Código | `HttpRemoteRepository.dart:195` | Medio-bajo | M | Recomendación (`compute`) |
| 17 | Vídeo de la visita: un mp4 a resolución completa en bucle infinito, sin calidad adaptativa | Código | `visit_screen.dart:173` | Medio (en Reels) | L | Recomendación (HLS) |
| 18 | Miniaturas decodificadas a tamaño completo (portadas de listas a 96×96 en la ficha; foto del mapa a 66×66) | Código | `curated_hero_image.dart:33` | Bajo (memoria) | S | Recomendación |
| 19 | `debugPrint` en cada build de la barra superior del Inicio y en cada rebuild de marcadores (también corre en release) | Código | `top_filter_bar.dart:29` | Bajo | S | **Arreglado** |
| 20 | Skeleton de Visitas con `Opacity` animado sobre una lista completa (saveLayer de pantalla completa) | Código | `visitas_screen.dart:307` | Bajo | S | Recomendación (`FadeTransition`) |
| 21 | `GET /video-ingestion/restaurant-videos/published` devolvía ~4 MB **sin comprimir** (337 visitas con `transcript` y `rawLlmResponse`): ~30 s de radio activa en cada arranque (lo piden el Inicio y la pestaña Visitas aunque no se abra) y, con el balanceador lento, el Inicio se quedaba en esqueletos | `curl`: >30 s, sin `Content-Encoding` | backend (migración 048) | Alto (red) | S | **Arreglo de backend en despliegue** (`8df5269`: sin esos campos + gzip). La app ya pide `gzip` (cliente de Dart por defecto): no hace falta tocarla |

## Arreglos de esta rama

Commits pequeños en `perf/energia`, sin cambios visibles:

| Commit | Qué cambia |
|---|---|
| `perf(nav): parar las animaciones de todas las pestañas ocultas` | Cada pestaña del `IndexedStack` va bajo `TickerMode(enabled: _index == i)`. |
| `perf(home): el cielo de estrellas ya no reconstruye en cada vsync` | Sin Ticker: el cielo es estático (ya lo era en pantalla). |
| `perf(motion): los bucles se paran fuera de pantalla` | `GmLoop` escucha su scroll vertical y se para fuera de la vista; el hero pausa nubes y lluvia al salir de pantalla; el borde de nubes graba el SVG una vez. |
| `perf(mapa): GPS solo con el mapa a la vista` | Punto azul y stream de GPS solo con la pestaña Mapa visible, sin otra ruta encima y en primer plano (`RouteAware` + ciclo de vida); al volver no mueve la cámara. |
| `perf(ubicacion): cancelar de verdad las lecturas que vencen` | `timeLimit` en vez de `Future.timeout`. |
| `perf(red): no revalidar la caché en cada acierto` | Revalidación en segundo plano solo si la entrada tiene más de 5 min (listas) o 30 min (referencia). Fichas, como antes. |
| `perf(home): log de la barra superior solo en debug` | `debugPrint` tras `kDebugMode`. |
| `perf(home): las nubes del hero se pintan una vez y solo se mueven` | Cada nube se rasteriza una vez con margen para el halo. Comparada con la original píxel a píxel: diferencia máxima 4/255 por canal. |
| `fix(red): no cachear respuestas de error y saltar entradas ilegibles` | Una respuesta no 2xx no se guarda; una entrada de caché ilegible va a la red. |
| `test(perf): …` | Censo de energía (`integration_test/perf/`, `test_driver/perf_driver.dart`). |

Tests nuevos (`test/ui/energy/energy_tickers_test.dart` y cuatro casos en
`test/data/http_remote_repository_cache_test.dart`): bucle fuera y dentro de
pantalla, reducir movimiento, estrellas sin fotogramas, pestañas ocultas con
los tickers apagados y caché sin revalidar un acierto reciente. **Fallan con
el código original y pasan con los arreglos.** El resto de la suite queda
igual: tras el rebase fallan 4 tests y los 4 ya fallaban en `874bdab`.

## Propuestas pendientes de decisión

Cambian algo visible o son decisiones de producto, así que no se han hecho.
Ordenadas por impacto:

1. **Quedarse en 60 Hz** (`CADisableMinimumFrameDurationOnPhone` a `false`).
   Divide por dos el coste de cada animación y de cada scroll en los iPhone
   ProMotion. Lo que se pierde: el scroll y las transiciones a 120 Hz, más
   suaves. Alternativa intermedia: mantener 120 Hz y aplicar la propuesta 3.
2. ***Session replay* de PostHog.** Opciones, de más a menos ahorro:
   apagarlo; muestrear sesiones desde el proyecto de PostHog (p. ej. 10 %);
   subir `throttleDelay` de 2 s a 5–10 s. Con los arreglos de esta rama la
   pantalla está quieta más a menudo y el replay ya se ahorra más subidas
   («Snapshot is the same as the last one»), pero sigue leyendo la pantalla
   de la GPU cada 2 s. Coste medido: ver «Mediciones».
3. **Pausar los bucles visibles tras unos segundos sin tocar la pantalla**
   (nubes del hero, borde de nubes, onda del punto «abierto»), y
   reanudarlos al primer toque o scroll. Con el Inicio arriba y quieto, son
   lo único que sigue pidiendo fotogramas. Alternativas: la onda del punto
   «abierto» hace 3 pulsos y se queda quieta; las nubes derivan a menos
   fotogramas por segundo (se mueven menos de 0,1 px por fotograma a 120 Hz).
4. **Quitar los desenfoques que no se ven**: la barra de pestañas va sobre un
   fundido al 94 % opaco y el velo superior del Ranking sobre uno al 96 %.
   El cristal apenas se nota y cada uno se recalcula en cada fotograma.
5. **Cargar la pestaña Mapa al abrirla por primera vez**, no al arrancar:
   ahorra ~23 peticiones encadenadas en cada arranque; la primera apertura
   del mapa tardaría lo que tarda hoy la carga.
6. **AdMob**: inicializarlo solo si alguna pantalla va a mostrar anuncios. El
   rediseño no muestra ninguno.
7. **Estirado del hero (I3 del QA)**: dar al hero un alto fijo y estirar solo
   la foto con un `Transform`, en vez de cambiar el alto de todo el bloque en
   cada fotograma. Cambia ligeramente cómo se ve el estirado; medir antes y
   después en un dispositivo.

## Otras recomendaciones

- **Medir en el iPhone** con el censo en profile y con Instruments (Power
  Profiler, Animation Hitches, Thermal State). Los comandos están en
  «Metodología». Repetirlo antes de cada subida a TestFlight convierte el
  censo en una prueba de regresión de energía.
- **Regla para animaciones nuevas**: todo bucle infinito usa `GmLoop` o
  `LoopingScene` (que ya se paran fuera de pantalla, en pestañas ocultas, con
  otra ruta encima, en segundo plano y con «reducir movimiento»). Nada de
  `AnimationController.repeat()` suelto.
- **Mapa**: sacar `_rebuildMarkers` de `build` y no hacer `setState` en cada
  fix de GPS si nada visible cambia; en iOS, sustituir el mapa de la ficha
  por una imagen estática.
- **Red**: `compute` para decodificar las páginas de restaurantes; un único
  `http.Client` compartido; evitar que Inicio y Mapa pidan las mismas páginas
  a la vez.
- **Vídeo**: HLS con calidades, o al menos una versión de 720p para Reels.
- **Imágenes**: `memCacheWidth` en `CuratedHeroImage` y en la miniatura del
  mapa (con margen para `BoxFit.cover`).
- **Logs**: revisar los `debugPrint` y `AppLogger.info` en caminos calientes;
  `AppLogger` escribe en Crashlytics en release.
