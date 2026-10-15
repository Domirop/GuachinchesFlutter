import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/login/login_logic.dart';
import 'package:guachinches/ui/pages/login/login_sheet.dart';
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_reviews_screen.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/rating_summary.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/review_card.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/write_review_screen.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// «Reseñas (N)» de la ficha (tablero FichaCompleta): resumen con la nota y
/// la distribución, tarjeta «Comparte tu experiencia» con estrellas que se
/// pulsan (→ login o WriteReviewScreen) o «Ya has reseñado este
/// restaurante» con Editar, y las tres primeras reseñas tal cual. «Ver todas
/// las reseñas» solo con más de tres.
class ReviewsSection extends StatefulWidget {
  final Restaurant restaurant;
  final VoidCallback? onReviewSubmitted;

  const ReviewsSection({
    super.key,
    required this.restaurant,
    this.onReviewSubmitted,
  });

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  static const _storage = FlutterSecureStorage();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await _storage.read(key: 'userId');
    if (!mounted) return;
    setState(() => _userId = id);
  }

  Review? get _myReview {
    if (_userId == null || _userId!.isEmpty) return null;
    for (final r in widget.restaurant.valoraciones) {
      if (r.valoracionesUsuarioId == _userId) return r;
    }
    return null;
  }

  Future<void> _openWriteReview(BuildContext context,
      {int initial = 0, Review? editing}) async {
    HapticFeedback.lightImpact();
    final userId = _userId ?? await _storage.read(key: 'userId');
    if (!context.mounted) return;
    if (userId == null || userId.isEmpty) {
      await _loginThenWrite(context, initial: initial);
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WriteReviewScreen(
          restaurant: widget.restaurant,
          initialRating: initial,
          existingReview: editing,
        ),
      ),
    );
    if (result == true) {
      widget.onReviewSubmitted?.call();
    }
  }

  /// Sin sesión: acceso único con el chip «Para escribir tu reseña»; al
  /// entrar vuelve aquí y abre el editor con las estrellas pulsadas.
  Future<void> _loginThenWrite(BuildContext context, {int initial = 0}) async {
    final ok = await showLoginSheet(context, reason: LoginReason.review);
    if (!ok || !context.mounted) return;
    await _loadUserId();
    if (!context.mounted || _userId == null || _userId!.isEmpty) return;
    // Si ya la había escrito con esa cuenta, se edita en vez de duplicarla.
    await _openWriteReview(context, initial: initial, editing: _myReview);
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final reviews = widget.restaurant.valoraciones;
    final hasReviews = reviews.isNotEmpty;
    final visible = reviews.take(3).toList();
    final myReview = _myReview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GmSectionHeader(
          title: hasReviews ? 'Reseñas (${reviews.length})' : 'Reseñas',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasReviews) ...[
                RatingSummary(restaurant: widget.restaurant),
                const SizedBox(height: 10),
              ],
              if (myReview != null)
                _AlreadyReviewedCard(
                  onEdit: () => _openWriteReview(context,
                      initial: double.tryParse(myReview.rating)?.round() ?? 0,
                      editing: myReview),
                )
              else
                _WriteReviewPrompt(
                  onStarTap: (rating) =>
                      _openWriteReview(context, initial: rating),
                ),
              if (!hasReviews) ...[
                const SizedBox(height: 12),
                Text(
                  'Sé el primero en compartir tu experiencia.',
                  textAlign: TextAlign.center,
                  style: GmText.meta(color: gm.label2),
                ),
              ],
              for (var i = 0; i < visible.length; i++) ...[
                const SizedBox(height: 10),
                ReviewCard(
                  review: visible[i],
                  index: i,
                  restaurantName: widget.restaurant.nombre,
                ),
              ],
              if (fichaShowAllReviews(reviews.length)) ...[
                const SizedBox(height: 12),
                Center(
                  child: Semantics(
                    identifier: 'restaurant-reviews-see-all-button',
                    button: true,
                    child: GmPressable(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RestaurantReviewsScreen(
                            restaurant: widget.restaurant,
                          ),
                        ),
                      ),
                      child: FichaPillButton(
                        label: 'Ver todas las reseñas',
                        trailing: GmIcons.chevronRight,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Botón píldora gris del sistema («Ver horario», «Editar», «Ver todas»).
class FichaPillButton extends StatelessWidget {
  final String label;
  final String? trailing;
  const FichaPillButton({super.key, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    // Control compacto: el texto escala como mucho a 1,3×.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
        decoration: BoxDecoration(
          color: gm.fill,
          borderRadius: BorderRadius.circular(GmRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GmText.sub(color: gm.label, w: FontWeight.w600)),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              GmIcon(trailing!, size: 12, color: gm.label),
            ],
          ],
        ),
      ),
    );
  }
}

// ── «Comparte tu experiencia» ───────────────────────────────────────────────

class _WriteReviewPrompt extends StatelessWidget {
  final ValueChanged<int> onStarTap;
  const _WriteReviewPrompt({required this.onStarTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'restaurant-reviews-write-prompt',
      container: true,
      child: GmCard(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        child: Column(
          children: [
            Text('Comparte tu experiencia',
                textAlign: TextAlign.center,
                style: GmText.body17(color: gm.label, w: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('Toca una estrella para empezar',
                textAlign: TextAlign.center,
                style: GmText.eyebrow(color: gm.label2, w: FontWeight.w400)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 5; i++)
                  Semantics(
                    button: true,
                    label: i == 0
                        ? 'Valorar con 1 estrella'
                        : 'Valorar con ${i + 1} estrellas',
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onStarTap(i + 1),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: GmOnce(
                            duration: const Duration(milliseconds: 560),
                            delay: Duration(milliseconds: 300 + i * 70),
                            child: GmIcon(GmIcons.starOutline,
                                size: 30, color: gm.label2),
                            builder: (_, t, c) {
                              final p = GmMotion.spring.transform(t);
                              return Transform.scale(
                                scale: 0.6 + 0.4 * p,
                                child: Transform.rotate(
                                  angle: -0.31 * (1 - p),
                                  child: c,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlreadyReviewedCard extends StatelessWidget {
  final VoidCallback onEdit;
  const _AlreadyReviewedCard({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'restaurant-reviews-already-reviewed',
      container: true,
      child: GmCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(color: gm.okSoft, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: GmIcon(GmIcons.check, size: 20, color: gm.greenText),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ya has reseñado este restaurante',
                      style:
                          GmText.body17(color: gm.label, w: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Gracias por contar tu experiencia.',
                      style:
                          GmText.eyebrow(color: gm.label2, w: FontWeight.w400)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              identifier: 'restaurant-reviews-edit-button',
              button: true,
              child: GmPressable(
                onTap: onEdit,
                child: const FichaPillButton(label: 'Editar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
