import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/login/login.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_reviews_screen.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/rating_summary.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/review_card.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/write_review_screen.dart';

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

  Future<void> _openWriteReview(BuildContext context, {int initial = 0}) async {
    HapticFeedback.lightImpact();
    final userId = _userId ?? await _storage.read(key: 'userId');
    if (!context.mounted) return;
    if (userId == null || userId.isEmpty) {
      _showAuthSheet(context);
      return;
    }
    if (_myReview != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ya has dejado una reseña para este restaurante.'),
          backgroundColor: AppColors.atlanticoOscuro,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WriteReviewScreen(
          restaurant: widget.restaurant,
          initialRating: initial,
        ),
      ),
    );
    if (result == true) {
      widget.onReviewSubmitted?.call();
    }
  }

  void _showAuthSheet(BuildContext context) {
    final brand = context.brand;
    showModalBottomSheet(
      context: context,
      backgroundColor: brand.elevated,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _AuthPromptSheet(
        onLogin: () {
          Navigator.pop(sheetCtx);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const Login(
                'Inicia sesión para dejar tu reseña.',
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviews = widget.restaurant.valoraciones;
    final hasReviews = reviews.isNotEmpty;
    final visible = reviews.take(3).toList();
    final myReview = _myReview;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'RESEÑAS',
                  style: AppTextStyles.displaySection(size: 11),
                ),
              ),
              if (hasReviews)
                Text(
                  '${reviews.length}',
                  style: AppTextStyles.ui(
                    size: 11,
                    color: context.brand.textMuted,
                    weight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasReviews) ...[
            RatingSummary(restaurant: widget.restaurant),
            const SizedBox(height: 12),
          ],
          if (myReview != null)
            _AlreadyReviewedCard(review: myReview)
          else
            _WriteReviewPrompt(
              onStarTap: (rating) =>
                  _openWriteReview(context, initial: rating),
              onTap: () => _openWriteReview(context),
            ),
          const SizedBox(height: 14),
          if (!hasReviews)
            Text(
              'Sé el primero en compartir tu experiencia.',
              style: AppTextStyles.ui(
                size: 12,
                color: context.brand.textMuted,
              ),
            )
          else ...[
            ...visible.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ReviewCard(review: r),
                )),
            if (reviews.length > 3)
              Center(
                child: Semantics(
                  identifier: 'restaurant-reviews-see-all-button',
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RestaurantReviewsScreen(
                            restaurant: widget.restaurant,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'VER TODAS LAS RESEÑAS →',
                      style: AppTextStyles.displaySection(size: 11)
                          .copyWith(color: AppColors.atlanticoClaro),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// CTA: tarjeta "Comparte tu experiencia" con 5 estrellas tapeables
// ─────────────────────────────────────────────────────────────────────

class _WriteReviewPrompt extends StatelessWidget {
  final ValueChanged<int> onStarTap;
  final VoidCallback onTap;

  const _WriteReviewPrompt({
    required this.onStarTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: brand.surface,
            border: Border.all(color: brand.borderStrong),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.atlantico.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.edit_note_rounded,
                      size: 20,
                      color: AppColors.atlanticoClaro,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comparte tu experiencia',
                          style: AppTextStyles.ui(
                            size: 14,
                            weight: FontWeight.w700,
                            color: brand.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Toca una estrella para empezar',
                          style: AppTextStyles.ui(
                            size: 11,
                            color: brand.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (i) {
                  final starN = i + 1;
                  return GestureDetector(
                    onTap: () => onStarTap(starN),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.star_outline_rounded,
                        size: 32,
                        color: brand.textMuted,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Bottom sheet: requiere sesión
// ─────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────
// Estado: el usuario ya ha dejado su reseña
// ─────────────────────────────────────────────────────────────────────

class _AlreadyReviewedCard extends StatelessWidget {
  final Review review;

  const _AlreadyReviewedCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final rating = double.tryParse(review.rating)?.round() ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: brand.surface,
        border: Border.all(color: AppColors.laurisilva.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.laurisilva.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 20,
              color: AppColors.laurisilva,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ya has reseñado este restaurante',
                  style: AppTextStyles.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: brand.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 13,
                        color: AppColors.sol,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthPromptSheet extends StatelessWidget {
  final VoidCallback onLogin;

  const _AuthPromptSheet({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: brand.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.atlantico.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.atlanticoClaro,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Inicia sesión para dejar tu reseña',
            textAlign: TextAlign.center,
            style: AppTextStyles.displayHero(size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            'Necesitas una cuenta para puntuar y comentar restaurantes.',
            textAlign: TextAlign.center,
            style: AppTextStyles.ui(
              size: 13,
              color: brand.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.atlantico,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: onLogin,
            child: Text(
              'INICIAR SESIÓN',
              style: AppTextStyles.displaySection(size: 12)
                  .copyWith(color: Colors.white, letterSpacing: 1.0),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Ahora no',
              style: AppTextStyles.ui(
                size: 13,
                weight: FontWeight.w600,
                color: brand.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

