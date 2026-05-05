import 'package:flutter/material.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Types.dart';

/// Sección "Especialidades canarias":
/// - Hero "GUACHINCHES TRADICIONALES" (mapea al Type "tradicional").
/// - Fila de chips temáticos: Carne de cabra, Cochino negro, Pescado fresco
///   (mapean a categorías por nombre, descartan los que no existan en BD).
class CanarianSpecialtiesSection extends StatelessWidget {
  final List<ModelCategory> categories;
  final List<Types> types;
  final void Function({
    List<ModelCategory>? categories,
    List<Types>? types,
  }) onSearchPreSelected;

  const CanarianSpecialtiesSection({
    super.key,
    required this.categories,
    required this.types,
    required this.onSearchPreSelected,
  });

  Types? _findType(String contains) {
    final c = contains.toLowerCase();
    for (final t in types) {
      if (t.nombre.toLowerCase().contains(c)) return t;
    }
    return null;
  }

  ModelCategory? _findCategory(String contains) {
    final c = contains.toLowerCase();
    for (final cat in categories) {
      if (cat.nombre.toLowerCase().contains(c)) return cat;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tradicional = _findType('tradicional');
    final chips = <_ChipDef>[
      _ChipDef('🐐', 'Carne de cabra', _findCategory('cabra')),
      _ChipDef('🐖', 'Cochino negro', _findCategory('cochino')),
      _ChipDef('🐟', 'Pescado fresco', _findCategory('pescado')),
    ].where((c) => c.category != null).toList();

    if (tradicional == null && chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tradicional != null)
            _TraditionalHero(
              onTap: () => onSearchPreSelected(types: [tradicional]),
            ),
          if (tradicional != null && chips.isNotEmpty)
            const SizedBox(height: 12),
          if (chips.isNotEmpty)
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final c = chips[i];
                  return _SpecialtyChip(
                    icon: c.icon,
                    label: c.label,
                    onTap: () =>
                        onSearchPreSelected(categories: [c.category!]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipDef {
  final String icon;
  final String label;
  final ModelCategory? category;
  _ChipDef(this.icon, this.label, this.category);
}

class _TraditionalHero extends StatefulWidget {
  final VoidCallback onTap;
  const _TraditionalHero({required this.onTap});

  @override
  State<_TraditionalHero> createState() => _TraditionalHeroState();
}

class _TraditionalHeroState extends State<_TraditionalHero> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A4D2E),
                Color(0xFF2D6E47),
                Color(0xFF4A8B5C),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Decoración tenue
                Positioned(
                  right: -8, top: -14,
                  child: Text(
                    '🌿',
                    style: TextStyle(
                      fontSize: 90,
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                ),
                Positioned(
                  right: 60, bottom: -22,
                  child: Text(
                    '🍷',
                    style: TextStyle(
                      fontSize: 74,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                ),
                // Contenido
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'AUTÉNTICO',
                              style: AppTextStyles.eyebrow(
                                size: 9,
                                color: Colors.white.withOpacity(0.7),
                              ).copyWith(letterSpacing: 1.6),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'GUACHINCHES TRADICIONALES',
                              style: AppTextStyles.displaySection(
                                size: 15,
                                color: Colors.white,
                              ).copyWith(letterSpacing: 0.6, height: 1.1),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Vino de la casa, mesa larga y carne canaria',
                              style: AppTextStyles.editorial(
                                size: 11,
                                color: Colors.white.withOpacity(0.88),
                              ).copyWith(height: 1.25),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialtyChip extends StatefulWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _SpecialtyChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_SpecialtyChip> createState() => _SpecialtyChipState();
}

class _SpecialtyChipState extends State<_SpecialtyChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 116,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.brand.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.brand.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: AppTextStyles.ui(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: context.brand.textPrimary,
                  letterSpacing: 0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
