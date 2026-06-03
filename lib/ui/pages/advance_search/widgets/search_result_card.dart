import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/utils/horarios_utils.dart';

class SearchResultCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  /// Cuando viene informado y el restaurante NO trae `mainFoto`, se usa
  /// como foto de la card. Pensado para los matches que llegan vía visitas
  /// (donde el backend del endpoint público no devuelve `fotos` en el
  /// `restaurant` embebido). Si está vacío o el restaurante ya tiene
  /// `mainFoto`, se ignora.
  final String? photoUrlOverride;

  /// Distancia ya formateada (p.ej. "88 m" / "1.6 km"). Cuando viene
  /// informada se antepone en el meta-line con icono de pin. La usa la
  /// pantalla "Abiertos cerca de ti"; en la búsqueda normal va null.
  final String? distance;

  const SearchResultCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.photoUrlOverride,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final categories = r.categoriaRestaurantes
        .map((c) => c.categorias.nombre)
        .where((n) => n.isNotEmpty)
        .toList();
    final categoryLine = categories.take(3).join(' · ');
    final effectivePhoto =
        r.mainFoto.isNotEmpty ? r.mainFoto : (photoUrlOverride ?? '');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Thumbnail(seed: r.id, photoUrl: effectivePhoto),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    r.nombre.toUpperCase(),
                    style: AppTextStyles.displaySection(size: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _MetaLine(restaurant: r, distance: distance),
                  if (categoryLine.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      categoryLine,
                      style: AppTextStyles.muted(size: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.brand.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String seed;
  final String photoUrl;

  const _Thumbnail({required this.seed, required this.photoUrl});

  static const _palette = <List<Color>>[
    [AppColors.laurisilva, Color(0xFF064B36)],
    [AppColors.tierra, Color(0xFF3D1500)],
    [AppColors.mojo, Color(0xFF8B2E0E)],
    [AppColors.atlantico, Color(0xFF003D5C)],
    [AppColors.sol, Color(0xFF7A5800)],
    [AppColors.arena, Color(0xFF6B4F22)],
  ];

  List<Color> get _gradient {
    if (seed.isEmpty) return _palette.first;
    final hash = seed.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return _palette[hash % _palette.length];
  }

  Widget _placeholder() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradient,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 64,
        height: 64,
        child: photoUrl.isEmpty
            ? _placeholder()
            : CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                memCacheWidth: 192,
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) => _placeholder(),
              ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final Restaurant restaurant;
  final String? distance;

  const _MetaLine({required this.restaurant, this.distance});

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final hasDistance = distance != null && distance!.isNotEmpty;
    final hasRating = r.avgRating > 0;
    final hasMunicipio = r.municipio.isNotEmpty;
    final hasPrice = r.minPrice != null && r.maxPrice != null;
    final isOpen = r.horariosJson != null
        ? getOpenStatus(r.horariosJson, DateTime.now()) == 'Abierto'
        : r.open;

    final children = <Widget>[];

    if (hasDistance) {
      children.add(_distanceChunk(distance!));
    }
    if (hasRating) {
      if (children.isNotEmpty) children.add(_dot(context));
      children.add(_ratingChunk(r.avgRating));
    }
    if (hasMunicipio) {
      if (children.isNotEmpty) children.add(_dot(context));
      children.add(_textChunk(context, r.municipio));
    }
    if (hasPrice) {
      if (children.isNotEmpty) children.add(_dot(context));
      children.add(_textChunk(context, '${r.minPrice}–${r.maxPrice}€'));
    }
    if (children.isNotEmpty) children.add(const SizedBox(width: 8));
    children.add(_OpenChip(isOpen: isOpen));

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 4,
      children: children,
    );
  }

  Widget _distanceChunk(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.place_rounded, size: 13, color: AppColors.atlantico),
        const SizedBox(width: 3),
        Text(
          text,
          style: AppTextStyles.chipLabel(size: 12, color: AppColors.atlantico),
        ),
      ],
    );
  }

  Widget _ratingChunk(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, size: 13, color: AppColors.sol),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.chipLabel(size: 12, color: AppColors.sol),
        ),
      ],
    );
  }

  Widget _dot(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          '·',
          style: AppTextStyles.ui(size: 12, color: context.brand.textMuted),
        ),
      );

  Widget _textChunk(BuildContext context, String text) => Text(
        text,
        style: AppTextStyles.ui(
          size: 12,
          weight: FontWeight.w400,
          color: context.brand.textPrimary,
        ),
      );
}

class _OpenChip extends StatelessWidget {
  final bool isOpen;
  const _OpenChip({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.laurisilva : AppColors.mojo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        isOpen ? 'ABIERTO' : 'CERRADO',
        style: AppTextStyles.chipLabel(size: 9, color: color),
      ),
    );
  }
}
