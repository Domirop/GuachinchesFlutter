Embeber los vídeos de YouTube dentro de la app usando la **IFrame Player API oficial** (`youtube_player_iframe`, ya en deps) **con fallback automático a `launchUrl` externo** cuando el embed falle. Hoy todo se redirige a la app nativa de YouTube con `launchUrl(LaunchMode.externalApplication)`; queremos UX dentro de la app SIN romper la garantía de que "el vídeo siempre se ve, sí o sí".

CONTEXTO ACTUAL (verificado a mano):

- `pubspec.yaml` ya tiene `youtube_player_iframe: ^5.2.2`, `youtube_player_flutter: ^8.1.2`, `webview_flutter: ^4.13.0`. **NO añadir deps nuevas.**
- Hoy hay 3 entry points que abren YouTube externo:
  * `lib/ui/pages/restaurant_detail/widgets/youtube_short_section.dart:22` — `_open()` lanza `youtube.com/shorts/<id>`.
  * `lib/ui/pages/restaurant_detail/widgets/del_video_section.dart:55` — `_QuoteCard._openAtTimestamp()` lanza `youtube.com/shorts/<id>?t=<s>`.
  * `lib/ui/pages/restaurant_detail/widgets/ntk_box.dart:51,70` — varios `launchUrl` (no necesariamente YouTube; **NO tocar** en este sprint, no es scope).
- `Visit.youtubeVideoId` (campo del modelo) y `Restaurant.shortVideoId` son las dos fuentes de ID en el cliente.
- Hay un detalle DEBUG visible: `del_video_section.dart:91-101` pinta el quote con `Container(color: Colors.yellow)` y texto en rojo con sufijo "[DBG]". **Quitar este debug ya que estamos por ahí — el render limpio era texto en blanco/negro con itálica.**

REQUISITO DURO DEL USUARIO: *"garantizame que el video carga si no carga me lo montas con redireccionar, controla los errores que devuelve"*. **NUNCA** debe quedar un tap sin respuesta. El fallback de redirección externa es obligatorio en cada error.

CONTRATO LEGAL — NO NEGOCIABLE:
- Usar **solo** `youtube_player_iframe` (carga la IFrame API oficial). NO extraer URL del MP4. NO cargar `youtube.com/watch?v=` en `webview_flutter` raw. Eso viola TOS de YouTube y bloquearía la app.
- En el código del componente principal añadir comentario explicando esto (para que ningún Generator futuro lo cambie).

CONTRATO FUNCIONAL:

1. **Nuevo componente `lib/ui/components/video/youtube_embed_with_fallback.dart`**:
   - `class YoutubeEmbedWithFallback extends StatefulWidget`.
   - Props: `String videoId` (req), `int? startSeconds`, `double aspectRatio = 16/9`, `VoidCallback? onClose`.
   - Estados internos:
     * `_initializing` (true durante los primeros 8s tras montar).
     * `_failed` (true si el controller emite error o pasa el timeout sin `playerState == playing`).
   - Si `videoId.isEmpty` o `videoId.length != 11` → renderiza directamente `_FallbackBlock` sin tocar el controller (early exit). Caso defensivo: nunca debería ocurrir si el caller filtra, pero asegura el contrato.
   - Construye `YoutubePlayerController.fromVideoId(videoId: videoId, autoPlay: true, startSeconds: startSeconds?.toDouble(), params: const YoutubePlayerParams(showControls: true, showFullscreenButton: true, strictRelatedVideos: true))`.
   - Suscribe al stream del controller. Captura:
     * `playerState == YoutubePlayerState.unknown` → log warning.
     * `error` events (códigos 2, 5, 100, 101, 150 — ver YouTube IFrame API ref). **Cualquier código → `_failed = true`**.
   - Timer de 8s desde initState: si no se ha emitido `playerState == playing` o `buffering` → `_failed = true`. Esto cubre el caso "el iframe carga pero queda en blanco" que ocurre en algunos vídeos con embedding restringido.
   - **`_FallbackBlock`** (widget privado): card con thumbnail estática (`https://img.youtube.com/vi/$videoId/0.jpg` ya viene servido por YouTube, sin auth) + botón grande "Abrir en YouTube" que llama `launchUrl(Uri.parse('https://youtube.com/watch?v=$videoId${startSeconds != null ? "&t=$startSeconds" : ""}'), mode: LaunchMode.externalApplication)`. Si **incluso ese launchUrl falla** (raro: device sin browser), mostrar SnackBar "No se pudo abrir el vídeo".
   - Anchors:
     * `youtube-embed-container` en el contenedor raíz.
     * `youtube-embed-player` en el `YoutubePlayer` cuando se renderiza.
     * `youtube-embed-fallback` en `_FallbackBlock` cuando se renderiza.
     * `youtube-embed-open-external-button` en el botón "Abrir en YouTube" (tanto del fallback como del botón secundario opcional en el header del sheet).
   - Logs (`AppLogger`):
     * tag `youtube-embed`:
       - `mounted videoId=<id> startSeconds=<n>`
       - `state_change <YoutubePlayerState>`
       - `error code=<n> message=<s>` (si el controller emite error)
       - `fallback_triggered reason=<timeout|error|invalid_id>`
       - `fallback_launch_success` / `fallback_launch_failed`

2. **Componente bottom sheet `lib/ui/components/video/youtube_embed_sheet.dart`**:
   - `class YoutubeEmbedSheet` con static `show(BuildContext context, {required String videoId, int? startSeconds})`.
   - `showModalBottomSheet` con `isScrollControlled: true`, `useSafeArea: true`, `backgroundColor: Colors.black`.
   - Contenido:
     * Header con drag handle + botón cerrar (X) + botón secundario "↗" que **siempre** está disponible para abrir externo (no esperando al fallback — patrón Twitter/Reddit).
     * `YoutubeEmbedWithFallback` ocupando el resto.
   - Anchor `youtube-embed-sheet-root`.

3. **Refactor `youtube_short_section.dart`**:
   - `_open()` cambia: en vez de `launchUrl` directo, llama `YoutubeEmbedSheet.show(context, videoId: restaurant.shortVideoId!)`.
   - Si `shortVideoId` es null/empty, la sección no se renderiza (ya hay `shouldRender`). No cambia.
   - Thumbnail y diseño visual del tile **NO se tocan**.

4. **Refactor `del_video_section.dart`**:
   - `_QuoteCard._openAtTimestamp()` cambia: llama `YoutubeEmbedSheet.show(context, videoId: videoId!, startSeconds: seconds)` en vez de `launchUrl`.
   - **Limpiar el debug visual** (lines 91-101): el `Container(color: Colors.yellow)` con texto rojo y `"[DBG]"` debe sustituirse por:
     ```dart
     Text(
       '"${quote.text}"',
       style: AppTextStyles.editorial(
         size: 13,
         color: context.brand.textPrimary,
       ).copyWith(fontStyle: FontStyle.italic),
     ),
     ```
   - El resto del `_QuoteCard` (border, padding, chip de timestamp) no se toca.

5. **NO MODIFICAR**:
   - `ntk_box.dart` (los launchUrl ahí no son a YouTube necesariamente).
   - `discover_screen.dart` ni `visit_list_tile.dart` (estos navegan al detalle, no abren vídeo directo — la apertura ocurre dentro del detalle ya cubierto).
   - `pubspec.yaml`, `ios/`, `android/` (deps ya están).
   - Cualquier cosa fuera de `lib/ui/components/video/` y los dos refactors arriba.

TESTS OBLIGATORIOS:

- **Unit / widget** (`test/ui/components/video/youtube_embed_with_fallback_test.dart`):
  * `videoId` vacío → renderiza `_FallbackBlock` sin intentar inicializar player (verificar finder por anchor `youtube-embed-fallback`).
  * `videoId` con longitud != 11 → idem fallback.
  * `videoId` válido → renderiza player + anchor `youtube-embed-player` (sin levantar webview real — el test puede mockear `YoutubePlayerController` vía un wrapper inyectable, o simplemente verificar que el widget se monta sin throw y los anchors están presentes).
  * Si el componente expone un método `_triggerFailureForTest()` o usa un `ValueNotifier` interno, simular un error y verificar swap a fallback. **Si arquitectónicamente es muy invasivo, OK con dejarlo cubierto por el test del sheet**.

- **Widget** (`test/ui/components/video/youtube_embed_sheet_test.dart`):
  * `YoutubeEmbedSheet.show(...)` con un `videoId` válido → encuentra anchor `youtube-embed-sheet-root` + botón `youtube-embed-open-external-button` siempre visible en el header.
  * Tap en cerrar → cierra el sheet.

- **Smoke regresión** (`test/ui/pages/restaurant_detail/widgets/del_video_section_test.dart`):
  * Renderizar `DelVideoSection` con un quote → texto se ve sin el debug yellow/red (el placeholder `[DBG]` no debe estar en el árbol).

PROHIBIDO (rechazo automático del Evaluator):

- Cargar URL `youtube.com/watch?v=` en `webview_flutter` raw.
- Extraer streams MP4 (cualquier librería tipo `youtube_explode_dart` o similar).
- Cambiar el diseño visual del tile del Short (es UX existente, no es scope).
- Dejar un tap sin fallback — si el embed falla y el botón externo también falla, debe haber al menos SnackBar de error. **Nunca silencio.**
- Tocar deps en `pubspec.yaml`.
- Modificar `ntk_box.dart`, `discover_screen.dart`, `visit_list_tile.dart`.
- Añadir un timeout < 5s (algunos embed tardan 6-7s en buffering inicial — falso positivo).
- Quitar el header "↗ Abrir en YouTube" del sheet (es opt-in para usuarios que prefieren la app nativa).

OUT OF SCOPE (mencionar en informe del Evaluator):

- Picture-in-Picture en iOS/Android.
- Cast a Chromecast / AirPlay.
- Pre-fetch del vídeo en la card antes del tap (performance + datos).
- Soporte para vídeos que NO son shorts (vídeos largos en YouTube Player). El cliente solo usa shorts hoy.
- Internacionalización del botón "Abrir en YouTube" — hardcoded en castellano OK por ahora; sprint #7 ya sentó la base de i18n pero migración deep screens es separada.

ENTREGA:

1. Diff con: 2 componentes nuevos en `lib/ui/components/video/`, refactor de 2 widgets existentes (`youtube_short_section.dart`, `del_video_section.dart`), tests unit+widget.
2. `flutter analyze` limpio en los ficheros nuevos/modificados (preexistentes ajenos OK).
3. `flutter test` de los 3 ficheros de test debe pasar al 100%.
4. Informe del Evaluator debe confirmar:
   - El embed se monta sin crash.
   - El fallback aparece cuando se simula error.
   - El botón "Abrir en YouTube" del header está siempre presente.
   - El debug yellow/red de `del_video_section.dart` desapareció.
   - **Garantía clave**: no hay path donde el usuario taps en un short y la app no responde.

Este sprint debe leerse en review en ≤ 15 min. Si el diff crece > 600 líneas (incl. tests), el Generator debe simplificar el sheet (puede ser un widget puro sin header complejo) y dejar polish para un segundo PR.
