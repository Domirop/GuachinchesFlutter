import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/pages/discover/visit_sentiment.dart';

/// "LO QUE PEDIMOS" — los platos de la visita, siempre como **lista** limpia.
///
/// El backend genera una foto por plato (migrations 031+032). Cuando un plato
/// trae `photoUrl`, su fila muestra una **miniatura tocable** que abre el visor
/// a pantalla completa (PageView por todas las fotos, con Hero). Los platos sin
/// foto muestran el punto de siempre. La lista no cambia de forma tenga fotos o
/// no — solo gana miniaturas donde las hay.
class DishesSection extends StatelessWidget {
  final List<VisitDish> dishes;

  /// Prefijo único para los `Hero` del visor (normalmente el id de la visita),
  /// para que dos visitas distintas no colisionen en el tag.
  final String heroPrefix;

  const DishesSection({
    super.key,
    required this.dishes,
    this.heroPrefix = 'dish',
  });

  static bool shouldRender(List<VisitDish> dishes) => dishes.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // Subconjunto con foto, en orden, para el visor swipeable (sin huecos).
    final photoDishes = [
      for (final d in dishes)
        if (d.photoUrl != null) d
    ];

    final rows = <Widget>[];
    var photoIndex = 0;
    for (var i = 0; i < dishes.length; i++) {
      final d = dishes[i];
      final hasPhoto = d.photoUrl != null;
      final pIdx = hasPhoto ? photoIndex : -1;
      if (hasPhoto) photoIndex++;
      rows.add(_DishRow(
        dish: d,
        isLast: i == dishes.length - 1,
        heroTag: hasPhoto ? '$heroPrefix-dish-$pIdx' : null,
        onTap: hasPhoto
            ? () => _openViewer(context, photoDishes, pIdx)
            : null,
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LO QUE PEDIMOS',
            style: AppTextStyles.displaySection(
              size: 11,
              color: AppColors.atlantico,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.brand.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.brand.border),
            ),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  void _openViewer(
      BuildContext context, List<VisitDish> photoDishes, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        // El fondo lo pinta el propio visor para poder aclararlo al arrastrar.
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => _DishPhotoViewer(
          dishes: photoDishes,
          initialIndex: index,
          heroPrefix: heroPrefix,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

class _DishRow extends StatelessWidget {
  final VisitDish dish;
  final bool isLast;

  /// No nulos solo cuando el plato tiene foto (fila tocable + hero).
  final String? heroTag;
  final VoidCallback? onTap;

  const _DishRow({
    required this.dish,
    required this.isLast,
    this.heroTag,
    this.onTap,
  });

  bool get _hasPhoto => heroTag != null;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: context.brand.border)),
      ),
      child: Row(
        children: [
          // Slot fijo 44px: miniatura si hay foto, punto centrado si no.
          // Mantiene el texto alineado en todas las filas.
          SizedBox(
            width: 44,
            height: 44,
            child: _hasPhoto
                ? Hero(
                    tag: heroTag!,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: dish.photoUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 96,
                        placeholder: (_, __) =>
                            Container(color: AppColors.cremaOscura),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.cremaOscura,
                          child: Icon(Icons.restaurant_rounded,
                              size: 18, color: context.brand.textMuted),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dish.isTop
                            ? AppColors.laurisilva
                            : Colors.grey.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dish.name,
              style: AppTextStyles.ui(
                size: 13,
                color: context.brand.textPrimary,
              ),
            ),
          ),
          if (dish.isTop) ...[
            const SizedBox(width: 8),
            const _TopBadge(),
          ],
          // Pista de "tocar para ver foto".
          if (_hasPhoto) ...[
            const SizedBox(width: 6),
            Icon(Icons.photo_outlined,
                size: 16, color: context.brand.textMuted),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        label: '${dish.name}, ver foto',
        button: true,
        child: row,
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  const _TopBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.laurisilva.withOpacity(0.15),
        border: Border.all(color: AppColors.laurisilva.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'TOP',
        style: AppTextStyles.chipLabel(size: 9, color: AppColors.laurisilva),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Visor a pantalla completa (PageView por los platos con foto)
// ─────────────────────────────────────────────────────────────────────────

class _DishPhotoViewer extends StatefulWidget {
  final List<VisitDish> dishes;
  final int initialIndex;
  final String heroPrefix;

  const _DishPhotoViewer({
    required this.dishes,
    required this.initialIndex,
    required this.heroPrefix,
  });

  @override
  State<_DishPhotoViewer> createState() => _DishPhotoViewerState();
}

class _DishPhotoViewerState extends State<_DishPhotoViewer>
    with SingleTickerProviderStateMixin {
  late final PageController _controller;
  late final AnimationController _resetCtrl;
  Animation<double>? _resetAnim;
  late int _index;

  /// Desplazamiento vertical acumulado del arrastre (px). 0 = en reposo.
  double _dragDy = 0;

  /// Umbral de cierre por distancia y por velocidad (flick).
  static const double _dismissDistance = 140;
  static const double _dismissVelocity = 700;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    _resetCtrl.dispose();
    super.dispose();
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
      Navigator.of(context).maybePop();
    } else {
      // Snap-back animado a su sitio.
      _resetAnim = Tween<double>(begin: _dragDy, end: 0).animate(
        CurvedAnimation(parent: _resetCtrl, curve: Curves.easeOut),
      );
      _resetCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Progreso del arrastre 0→1 sobre ~300px: dosifica fondo y escala.
    final progress = (_dragDy.abs() / 300).clamp(0.0, 1.0);
    final bgOpacity = 0.92 * (1 - progress * 0.7);
    final scale = 1 - progress * 0.12;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fondo controlado por el arrastre (se aclara al bajar).
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withOpacity(bgOpacity)),
          ),
          // Contenido arrastrable: sigue el dedo + escala leve.
          Transform.translate(
            offset: Offset(0, _dragDy),
            child: Transform.scale(
              scale: scale,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.dishes.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _ViewerPage(
                    dish: widget.dishes[i],
                    heroTag: '${widget.heroPrefix}-dish-$i',
                  ),
                ),
              ),
            ),
          ),
          // Cerrar + contador: fijos (no se mueven con el arrastre).
          Positioned(
            top: media.padding.top + 8,
            right: 12,
            child: _CircleIconButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          if (widget.dishes.length > 1)
            Positioned(
              top: media.padding.top + 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.dishes.length}',
                    style: AppTextStyles.ui(
                      size: 12,
                      color: Colors.white,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ViewerPage extends StatelessWidget {
  final VisitDish dish;
  final String heroTag;

  const _ViewerPage({required this.dish, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final sentiment = dish.sentiment;
    final sColor =
        sentiment != null ? sentimentColor(_mapSentiment(sentiment)) : null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 8),
            child: Center(
              child: Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: CachedNetworkImage(
                      imageUrl: dish.photoUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 720,
                      placeholder: (_, __) =>
                          Container(color: Colors.white10),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.white10,
                        child: const Icon(Icons.restaurant_rounded,
                            color: Colors.white38, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              20, 4, 20, MediaQuery.of(context).padding.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (dish.isTop) ...[
                    const _TopBadge(),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      dish.name,
                      style: AppTextStyles.displaySection(
                          size: 18, color: Colors.white),
                    ),
                  ),
                  if (dish.price != null)
                    Text(
                      '${dish.price!.toStringAsFixed(dish.price! % 1 == 0 ? 0 : 2)} €',
                      style: AppTextStyles.ui(
                          size: 15,
                          color: Colors.white,
                          weight: FontWeight.w700),
                    ),
                ],
              ),
              if (sColor != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: sColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      kSentimentLabels[_mapSentiment(sentiment!)] ?? '',
                      style: AppTextStyles.ui(
                          size: 12,
                          color: Colors.white70,
                          weight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
              if (dish.description != null &&
                  dish.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  dish.description!,
                  style: AppTextStyles.ui(size: 13, color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _mapSentiment(String s) {
    switch (s.toLowerCase()) {
      case 'loved':
        return 'muy_positivo';
      case 'liked':
        return 'positivo';
      case 'neutral':
      case 'neutro':
        return 'neutro';
      case 'disliked':
      case 'negative':
      case 'negativo':
        return 'negativo';
      default:
        return s.toLowerCase();
    }
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
