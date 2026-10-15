import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show BaseCacheManager;
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/dish_viewer_logic.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

/// Visor de fotos de plato a pantalla completa (tablero `PlatoVisor`, mismo
/// patrón que `FichaGaleria`): negro puro, foto con `contain`, Cerrar y
/// Compartir de cristal, contador «5 / 6», nombre, precio y sello, nota, pie
/// «Casa Ángela · Visita del 8 oct 2026» y tira de miniaturas con la actual
/// anillada. Se pasa de plato deslizando y se cierra arrastrando en vertical.
///
/// Los `Hero` usan `'$heroPrefix-dish-$i'`: quien abre el visor pinta la
/// miniatura con el mismo tag. [placeName] y [visitDateIso] alimentan el pie
/// y el texto de compartir; si faltan se sacan de [visit] (si la hay).
void showDishPhotoViewer(
  BuildContext context, {
  required List<VisitDish> dishes,
  int initialIndex = 0,
  String heroPrefix = 'dish',
  String? placeName,
  String? visitDateIso,
  Visit? visit,
}) {
  if (dishes.isEmpty) return;
  final reduced = GmMotion.reduced(context);
  final place =
      placeName ?? (visit == null ? null : dishViewerPlaceName(visit));
  final date = visitDateIso ?? visit?.sortDate;
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration:
          reduced ? Duration.zero : const Duration(milliseconds: 260),
      reverseTransitionDuration:
          reduced ? Duration.zero : const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => DishPhotoViewer(
        dishes: dishes,
        initialIndex: initialIndex.clamp(0, dishes.length - 1),
        heroPrefix: heroPrefix,
        placeName: place,
        visitDateIso: date,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

// Colores fijos: el visor es siempre negro (día y noche).
const _skeleton = Color(0xFF161412);
const _thumbBg = Color(0xFF1A1A1A);
const _amber = Color(0xFFF2B84B);

/// Medidas de la tira de miniaturas.
const double _thumb = 52;
const double _thumbGap = 10;
const double _thumbPad = 16;

/// Visor (público para tests; ábrelo con [showDishPhotoViewer]).
class DishPhotoViewer extends StatefulWidget {
  final List<VisitDish> dishes;
  final int initialIndex;
  final String heroPrefix;
  final String? placeName;
  final String? visitDateIso;

  /// Caché de imágenes (por defecto la de `cached_network_image`); los tests
  /// pasan una falsa para no tocar la red.
  final BaseCacheManager? cacheManager;

  const DishPhotoViewer({
    super.key,
    required this.dishes,
    this.initialIndex = 0,
    this.heroPrefix = 'dish',
    this.placeName,
    this.visitDateIso,
    this.cacheManager,
  });

  @override
  State<DishPhotoViewer> createState() => _DishPhotoViewerState();
}

class _DishPhotoViewerState extends State<DishPhotoViewer>
    with SingleTickerProviderStateMixin {
  late final PageController _controller;
  late final AnimationController _resetCtrl;
  final ScrollController _thumbs = ScrollController();
  Animation<double>? _resetAnim;
  late int _index;

  /// Desplazamiento vertical acumulado del arrastre (px). 0 = en reposo.
  double _dragDy = 0;

  /// Umbral de cierre por distancia y por velocidad (flick).
  static const double _dismissDistance = 140;
  static const double _dismissVelocity = 700;

  int get _count => widget.dishes.length;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
    _resetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_resetAnim != null) setState(() => _dragDy = _resetAnim!.value);
      });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _centreThumb(_index, animate: false));
  }

  @override
  void dispose() {
    _controller.dispose();
    _resetCtrl.dispose();
    _thumbs.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  void _share() {
    final d = widget.dishes[_index];
    SharePlus.instance.share(ShareParams(
      text: dishShareText(
        dishName: d.name,
        placeName: widget.placeName,
        photoUrl: d.photoUrl,
      ),
    ));
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    _centreThumb(i, animate: !GmMotion.reduced(context));
  }

  void _centreThumb(int i, {required bool animate}) {
    if (!mounted || !_thumbs.hasClients) return;
    final target = dishThumbOffset(
      index: i,
      count: _count,
      viewport: _thumbs.position.viewportDimension,
      size: _thumb,
      gap: _thumbGap,
      padding: _thumbPad,
    ).clamp(0.0, _thumbs.position.maxScrollExtent);
    if (animate) {
      _thumbs.animateTo(target,
          duration: const Duration(milliseconds: 280), curve: GmMotion.settle);
    } else {
      _thumbs.jumpTo(target);
    }
  }

  void _goTo(int i) {
    if (i == _index) return;
    if (GmMotion.reduced(context) || (i - _index).abs() > 1) {
      _controller.jumpToPage(i);
    } else {
      _controller.animateToPage(i,
          duration: const Duration(milliseconds: 280), curve: GmMotion.settle);
    }
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _resetCtrl.stop();
    setState(() => _dragDy += d.delta.dy);
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dy;
    final dismiss = _dragDy.abs() > _dismissDistance ||
        (v.abs() > _dismissVelocity && _dragDy.abs() > 24);
    if (dismiss) {
      _close();
    } else if (GmMotion.reduced(context)) {
      setState(() => _dragDy = 0);
    } else {
      // Vuelve a su sitio.
      _resetAnim = Tween<double>(begin: _dragDy, end: 0).animate(
        CurvedAnimation(parent: _resetCtrl, curve: Curves.easeOut),
      );
      _resetCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Progreso del arrastre 0→1 sobre ~300 px: dosifica fondo, escala y
    // controles.
    final progress = (_dragDy.abs() / 300).clamp(0.0, 1.0);
    final bgOpacity = 1 - progress * 0.7;
    final scale = 1 - progress * 0.12;
    final chrome = (1 - progress * 1.6).clamp(0.0, 1.0);
    final top = math.max(media.padding.top, 20.0);
    final bottom = math.max(media.padding.bottom, 16.0);
    final multi = _count > 1;
    // Hueco que reserva cada página bajo el texto (tira + margen inferior).
    final reserve = multi ? bottom + _thumb + 8 + 28 : bottom + 16;
    final footer = dishViewerFooter(
        placeName: widget.placeName, visitDateIso: widget.visitDateIso);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: bgOpacity)),
          ),
          // Contenido arrastrable: sigue el dedo + escala leve.
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, _dragDy),
              child: Transform.scale(
                scale: scale,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _count,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (_, i) => _DishPage(
                      dish: widget.dishes[i],
                      heroTag: '${widget.heroPrefix}-dish-$i',
                      footer: footer,
                      cacheManager: widget.cacheManager,
                      topInset: top + 44 + 14,
                      bottomInset: reserve,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Barra superior fija: Cerrar · «5 / 6» · Compartir.
          Positioned(
            top: top,
            left: 16,
            right: 16,
            child: Opacity(
              opacity: chrome,
              child: IgnorePointer(
                ignoring: chrome < 0.5,
                child: Row(
                  children: [
                    GmToolbarButton(
                      icon: GmIcons.close,
                      onTap: _close,
                      semanticLabel: 'Cerrar',
                      identifier: 'dish-viewer-close',
                    ),
                    Expanded(
                      child: multi
                          ? Center(
                              child: _Counter(index: _index, total: _count))
                          : const SizedBox.shrink(),
                    ),
                    GmToolbarButton(
                      icon: GmIcons.share,
                      iconSize: 19,
                      onTap: _share,
                      semanticLabel: 'Compartir',
                      identifier: 'dish-viewer-share',
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (multi)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottom - 4,
              child: Opacity(
                opacity: chrome,
                child: IgnorePointer(
                  ignoring: chrome < 0.5,
                  child: _ThumbStrip(
                    controller: _thumbs,
                    dishes: widget.dishes,
                    current: _index,
                    cacheManager: widget.cacheManager,
                    onTap: _goTo,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// «5 / 6» en cápsula de cristal oscuro (36 de alto).
class _Counter extends StatelessWidget {
  final int index;
  final int total;
  const _Counter({required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'dish-viewer-counter',
      label: 'Plato ${index + 1} de $total',
      excludeSemantics: true,
      child: SizedBox(
        height: 36,
        child: GmGlass(
          borderRadius: BorderRadius.circular(GmRadius.pill),
          tint: const Color(0x4D1C1612),
          edge: const Color(0x66FFFFFF),
          edgeWidth: 0.5,
          blur: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              widthFactor: 1,
              child: Text(
                dishViewerCounter(index, total),
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 15,
                  height: 20 / 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Una página: foto (Hero) y, debajo, nombre, precio · sello, nota y pie.
class _DishPage extends StatelessWidget {
  final VisitDish dish;
  final String heroTag;
  final String? footer;
  final BaseCacheManager? cacheManager;
  final double topInset;
  final double bottomInset;

  const _DishPage({
    required this.dish,
    required this.heroTag,
    required this.footer,
    required this.cacheManager,
    required this.topInset,
    required this.bottomInset,
  });

  @override
  Widget build(BuildContext context) {
    final price = dishPriceLabel(dish.price);
    final stamp = dishStampOf(dish);
    final note = dish.description?.trim() ?? '';
    final url = dish.photoUrl;
    return Padding(
      padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: url == null || url.isEmpty
                ? const _PhotoSkeleton()
                : Center(
                    child: Hero(
                      tag: heroTag,
                      child: _DishPhoto(
                        url: url,
                        name: dish.name,
                        cacheManager: cacheManager,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dish.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GmText.title2(color: Colors.white),
                ),
                if (price != null || stamp != DishStamp.none) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (price != null) ...[
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 20 / 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (stamp != DishStamp.none) ...[
                          const SizedBox(width: 8),
                          const ExcludeSemantics(
                            child: Text('·',
                                style: TextStyle(
                                    fontSize: 15, color: Color(0x80FFFFFF))),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                      if (stamp == DishStamp.loved) const DishLovedStamp(),
                      if (stamp == DishStamp.disliked)
                        const DishDislikedStamp(),
                    ],
                  ),
                ],
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    note,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GmText.body(color: const Color(0xC7FFFFFF))
                        .copyWith(height: 21 / 15),
                  ),
                ],
                if (footer != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    footer!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GmText.meta(color: const Color(0x99FFFFFF)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sello «Les encantó» (vino, pulgar oro, texto #E8CF9A). Mismo aspecto que
/// `FichaLovedSeal` de la ficha; vive aquí para no arrastrar el grafo de la
/// ficha al visor (candidato a subir a `lib/ui/theme`).
class DishLovedStamp extends StatelessWidget {
  const DishLovedStamp({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: GmColors.wine,
        borderRadius: BorderRadius.circular(GmRadius.pill),
        border: Border.all(color: const Color(0x80C9A96B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GmIcon(GmIcons.thumb, size: 12, color: GmColors.gold),
          const SizedBox(width: 5),
          const Text(
            'Les encantó',
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE8CF9A),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sello ámbar «No les convenció».
class DishDislikedStamp extends StatelessWidget {
  const DishDislikedStamp({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(GmRadius.pill),
        border: Border.all(color: _amber.withValues(alpha: 0.45)),
      ),
      child: const Text(
        'No les convenció',
        maxLines: 1,
        style: TextStyle(
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w700,
          color: _amber,
        ),
      ),
    );
  }
}

/// Foto del plato con `contain`, esqueleto mientras carga y error con
/// «Reintentar» (saca la foto de la caché y vuelve a pedirla).
class _DishPhoto extends StatefulWidget {
  final String url;
  final String name;
  final BaseCacheManager? cacheManager;
  const _DishPhoto(
      {required this.url, required this.name, required this.cacheManager});

  @override
  State<_DishPhoto> createState() => _DishPhotoState();
}

class _DishPhotoState extends State<_DishPhoto> {
  int _attempt = 0;

  Future<void> _retry() async {
    try {
      await CachedNetworkImage.evictFromCache(widget.url,
          cacheManager: widget.cacheManager);
    } catch (e, st) {
      AppLogger.error('dish-viewer', e, st);
    }
    if (mounted) setState(() => _attempt++);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final decode =
        math.min(1080, (media.size.width * media.devicePixelRatio).round());
    return Semantics(
      image: true,
      label: widget.name,
      child: CachedNetworkImage(
        key: ValueKey('${widget.url}#$_attempt'),
        imageUrl: widget.url,
        cacheManager: widget.cacheManager,
        fit: BoxFit.contain,
        memCacheWidth: decode,
        fadeInDuration: GmMotion.reduced(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        placeholder: (_, __) => const _PhotoSkeleton(),
        errorListener: (e) =>
            AppLogger.warn('dish-viewer', 'photo_load_failed: $e'),
        errorWidget: (_, __, ___) => _PhotoError(onRetry: _retry),
      ),
    );
  }
}

/// Esqueleto oscuro de la foto (rectángulo a todo el ancho).
class _PhotoSkeleton extends StatelessWidget {
  const _PhotoSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando foto',
      child: const FractionallySizedBox(
        widthFactor: 1,
        heightFactor: 0.8,
        child: ColoredBox(color: _skeleton),
      ),
    );
  }
}

/// Error de una foto: volcán triste en oscuro, copia y «Reintentar».
class _PhotoError extends StatelessWidget {
  final VoidCallback onRetry;
  const _PhotoError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: CustomPaint(
                    size: const Size(100, 70),
                    painter: GmSadVolcanoPainter(GmColors.night),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No pudimos cargar la foto',
                  textAlign: TextAlign.center,
                  style: GmText.poster(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisa tu conexión e inténtalo de nuevo.',
                  textAlign: TextAlign.center,
                  style: GmText.body(color: const Color(0xB8FFFFFF))
                      .copyWith(height: 21 / 15),
                ),
                const SizedBox(height: 18),
                GmCapsuleButton(
                  label: 'Reintentar',
                  identifier: 'dish-viewer-retry-button',
                  onTap: onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tira de miniaturas 52 × 52 r12 (la actual con anillo 2 negro + 2 blanco,
/// el resto a .55), centrada si cabe y desplazable si no.
class _ThumbStrip extends StatelessWidget {
  final ScrollController controller;
  final List<VisitDish> dishes;
  final int current;
  final BaseCacheManager? cacheManager;
  final ValueChanged<int> onTap;

  const _ThumbStrip({
    required this.controller,
    required this.dishes,
    required this.current,
    required this.cacheManager,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(builder: (context, c) {
      return SizedBox(
        height: _thumb + 8,
        child: SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: _thumbPad, vertical: 4),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: c.maxWidth - _thumbPad * 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < dishes.length; i++) ...[
                  if (i > 0) const SizedBox(width: _thumbGap),
                  _Thumb(
                    index: i,
                    dish: dishes[i],
                    selected: i == current,
                    decodeWidth: (_thumb * dpr).round(),
                    cacheManager: cacheManager,
                    onTap: () => onTap(i),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _Thumb extends StatelessWidget {
  final int index;
  final VisitDish dish;
  final bool selected;
  final int decodeWidth;
  final BaseCacheManager? cacheManager;
  final VoidCallback onTap;

  const _Thumb({
    required this.index,
    required this.dish,
    required this.selected,
    required this.decodeWidth,
    required this.cacheManager,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final url = dish.photoUrl;
    final reduced = GmMotion.reduced(context);
    return Semantics(
      identifier: 'dish-viewer-thumb-$index',
      label: dish.name,
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: selected ? 1 : 0.55,
          duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
          child: Container(
            width: _thumb,
            height: _thumb,
            decoration: BoxDecoration(
              color: _thumbBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? const [
                      BoxShadow(color: Colors.white, spreadRadius: 4),
                      BoxShadow(color: Colors.black, spreadRadius: 2),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: url == null || url.isEmpty
                  ? const SizedBox.expand()
                  : CachedNetworkImage(
                      imageUrl: url,
                      cacheManager: cacheManager,
                      fit: BoxFit.cover,
                      memCacheWidth: decodeWidth,
                      placeholder: (_, __) => const SizedBox.expand(),
                      errorWidget: (_, __, ___) => const SizedBox.expand(),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
