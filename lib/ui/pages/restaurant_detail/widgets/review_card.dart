import 'package:flutter/material.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/ui/pages/restaurant_detail/review_moderation.dart';
import 'package:guachinches/ui/pages/restaurant_detail/reviews_logic.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/review_moderation_sheets.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Reseña tal cual la escribió cada persona (tableros FichaCompleta y
/// ResenasTodas): avatar con la inicial sobre un fondo teñido, nombre de
/// pila, estrellas, título y texto literales (sin los rellenos «Título» y
/// «Sin descripción»), «Leer más» en las largas y «⋯» de 44 con Reportar /
/// Bloquear. Sin fecha (el modelo no la trae).
///
/// Escucha a [ReviewModeration]: si la reseña está reportada se pinta
/// «Reseña oculta · Deshacer»; si su autor está bloqueado, no se pinta.
class ReviewCard extends StatefulWidget {
  final Review review;

  /// Posición en la lista: elige el tinte del avatar (azul, vino, verde).
  final int index;

  /// Nombre del sitio (para el correo a soporte de los invitados).
  final String restaurantName;

  /// `false` oculta el «⋯» (p. ej. en tu propia reseña).
  final bool showActions;

  final ReviewModeration? moderation;

  const ReviewCard({
    super.key,
    required this.review,
    this.index = 0,
    this.restaurantName = '',
    this.showActions = true,
    this.moderation,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _expanded = false;

  ReviewModeration get _mod => widget.moderation ?? ReviewModeration.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _mod,
      builder: (context, _) {
        final r = widget.review;
        if (_mod.isBlocked(reviewAuthorId(r))) return const SizedBox.shrink();
        if (r.id.isNotEmpty && _mod.isHidden(r.id)) {
          return _HiddenReviewCard(onUndo: () => _mod.undo(r.id));
        }
        return _content(context);
      },
    );
  }

  Widget _content(BuildContext context) {
    final gm = GmColors.of(context);
    final review = widget.review;
    final name = reviewAuthorName(review);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final stars = reviewStars(review);
    final palettes = [
      (gm.avAbg, gm.avAink),
      (gm.avTbg, gm.avTink),
      (gm.avPbg, gm.avPink),
    ];
    final (bg, ink) = palettes[widget.index % palettes.length];
    final title = reviewDisplayTitle(review.title);
    final text = reviewDisplayText(review.review);
    final long = reviewIsLong(text);
    final mine = _mod.cachedUserId != null &&
        _mod.cachedUserId == reviewAuthorId(review);

    return Semantics(
      identifier: 'restaurant-review-card-${review.id}',
      container: true,
      child: GmCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration:
                        BoxDecoration(color: bg, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.cardTitle(color: gm.label)
                            .copyWith(letterSpacing: 0),
                      ),
                      const SizedBox(height: 2),
                      ReviewStars(stars: stars),
                    ],
                  ),
                ),
                if (widget.showActions && !mine && review.id.isNotEmpty)
                  Transform.translate(
                    offset: const Offset(10, 0),
                    child: Semantics(
                      identifier: 'restaurant-review-more-${review.id}',
                      button: true,
                      label: 'Más opciones de la reseña de $name',
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => openReviewActions(
                          context,
                          review: review,
                          restaurantName: widget.restaurantName,
                          moderation: widget.moderation,
                        ),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child:
                                GmIcon(_kMoreIcon, size: 20, color: gm.label2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (title.isNotEmpty || text.isNotEmpty) const SizedBox(height: 10),
            if (title.isNotEmpty)
              Text(
                title,
                style: GmText.cardTitle(color: gm.label)
                    .copyWith(letterSpacing: -0.25),
              ),
            if (title.isNotEmpty && text.isNotEmpty) const SizedBox(height: 4),
            if (text.isNotEmpty)
              Text(
                text,
                maxLines: long && !_expanded ? 4 : null,
                overflow: long && !_expanded ? TextOverflow.ellipsis : null,
                style: TextStyle(
                  fontSize: 15,
                  height: 21 / 15,
                  fontWeight: FontWeight.w400,
                  color: gm.label,
                ),
              ),
            if (long)
              Semantics(
                identifier: 'restaurant-review-read-more-${review.id}',
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _expanded ? 'Leer menos' : 'Leer más',
                      style: GmText.body(color: gm.label, w: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Cinco estrellas (llenas en `star`, vacías en `label2` al 28 %).
class ReviewStars extends StatelessWidget {
  final int stars;
  final double size;
  const ReviewStars({super.key, required this.stars, this.size = 13});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      label: '$stars de 5 estrellas',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(right: 1),
              child: Semantics(
                identifier:
                    i < stars ? 'review-star-filled' : 'review-star-empty',
                child: GmIcon(GmIcons.star,
                    size: size,
                    color: i < stars
                        ? GmColors.star
                        : gm.label2.withValues(alpha: 0.28)),
              ),
            ),
        ],
      ),
    );
  }
}

/// «Reseña oculta · La has reportado. La revisaremos. · Deshacer».
class _HiddenReviewCard extends StatelessWidget {
  final VoidCallback onUndo;
  const _HiddenReviewCard({required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'restaurant-review-hidden',
      container: true,
      child: GmCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: gm.fill, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: GmIcon(reviewFlagIcon, size: 18, color: gm.label2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reseña oculta',
                      style: GmText.cardTitle(color: gm.label)
                          .copyWith(letterSpacing: 0)),
                  const SizedBox(height: 2),
                  Text('La has reportado. La revisaremos.',
                      style: GmText.meta(color: gm.label2)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GmSoftCapsuleButton(
              label: 'Deshacer',
              height: 36,
              fontSize: 14,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              identifier: 'restaurant-review-undo',
              onTap: onUndo,
            ),
          ],
        ),
      ),
    );
  }
}

const _kMoreIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">'
    '<circle cx="5.5" cy="12" r="1.8"/><circle cx="12" cy="12" r="1.8"/>'
    '<circle cx="18.5" cy="12" r="1.8"/></svg>';
