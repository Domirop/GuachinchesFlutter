import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/curated_list.dart';

class CuratedListItemCard extends StatelessWidget {
  final CuratedListItem item;
  final Color accent;
  final String fallbackEyebrow;
  final VoidCallback onTap;

  /// Distancia ya formateada del usuario al negocio (ej. `320 m`, `1,2 km`).
  /// `null` cuando no hay ubicación o el negocio no tiene coordenadas.
  final String? distanceLabel;

  const CuratedListItemCard({
    super.key,
    required this.item,
    required this.accent,
    required this.fallbackEyebrow,
    required this.onTap,
    this.distanceLabel,
  });

  String get _rank => item.position.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final restaurant = item.restaurant;
    final name = (restaurant?.nombre ?? '').toUpperCase();
    final municipio = restaurant?.municipio;
    final foto = restaurant?.mainFoto;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cremaSoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderCream),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(
              foto: foto,
              accent: accent,
              rank: _rank,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _Eyebrow(
                          eyebrow: fallbackEyebrow,
                          municipio: municipio,
                        ),
                      ),
                      if (distanceLabel != null &&
                          distanceLabel!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _DistancePill(label: distanceLabel!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.displayHero(
                            size: 22,
                            color: AppColors.ink,
                          ).copyWith(height: 1.05),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FavButton(color: accent),
                    ],
                  ),
                  if ((item.note ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(color: accent, width: 3),
                        ),
                      ),
                      child: Text(
                        '"${item.note!.trim()}"',
                        style: AppTextStyles.editorial(
                          size: 12,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        'VER FICHA',
                        style: AppTextStyles.eyebrow(
                          size: 10,
                          color: AppColors.atlantico,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.atlantico,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String? foto;
  final Color accent;
  final String rank;

  const _Hero({
    required this.foto,
    required this.accent,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background — foto or accent gradient
          if (foto != null && foto!.isNotEmpty)
            Image.network(
              foto!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradient(),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return _gradient();
              },
            )
          else
            _gradient(),
          // Bottom scrim for legibility
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.20),
                ],
              ),
            ),
          ),
          // Position badge — top-left
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.ink.withOpacity(0.78),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'N° $rank',
                style: AppTextStyles.eyebrow(
                  size: 11,
                  color: AppColors.crema,
                ).copyWith(letterSpacing: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradient() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withOpacity(0.55),
              accent.withOpacity(0.25),
              AppColors.cremaOscura,
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
      );
}

class _Eyebrow extends StatelessWidget {
  final String eyebrow;
  final String? municipio;

  const _Eyebrow({required this.eyebrow, required this.municipio});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (eyebrow.isNotEmpty) parts.add(eyebrow.toUpperCase());
    if (municipio != null && municipio!.isNotEmpty) {
      parts.add(municipio!.toUpperCase());
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join('  ·  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.eyebrow(
        size: 10,
        color: AppColors.inkMuted,
      ),
    );
  }
}

/// Pill de distancia (icono brújula + texto), color atlántico — misma seña
/// que la card de "Cerca de ti" del home para que se lean como lo mismo.
class _DistancePill extends StatelessWidget {
  final String label;

  const _DistancePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.atlantico.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_rounded,
              size: 11, color: AppColors.atlantico),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.ui(
              size: 11,
              weight: FontWeight.w700,
              color: AppColors.atlantico,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavButton extends StatefulWidget {
  final Color color;
  const _FavButton({required this.color});

  @override
  State<_FavButton> createState() => _FavButtonState();
}

class _FavButtonState extends State<_FavButton> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _liked = !_liked),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _liked ? widget.color.withOpacity(0.12) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: _liked ? widget.color : AppColors.borderCreamMd,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          _liked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          size: 18,
          color: _liked ? widget.color : AppColors.inkMuted,
        ),
      ),
    );
  }
}
