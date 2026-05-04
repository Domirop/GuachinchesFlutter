import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/Category.dart';

/// Fila horizontal de chips de categoría.
/// "TODOS" es siempre el primer elemento (id == null).
class CategoryChipRow extends StatelessWidget {
  final List<ModelCategory> categories;
  final String? selectedId; // null → TODOS
  final ValueChanged<String?> onSelect;

  const CategoryChipRow({
    super.key,
    required this.categories,
    this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _CategoryChip(
              label: 'TODOS',
              icon: '☀️',
              active: selectedId == null,
              onTap: () => onSelect(null),
            );
          }
          final cat = categories[i - 1];
          return _CategoryChip(
            label: cat.nombre.toUpperCase(),
            icon: _iconForCategory(cat.nombre),
            active: selectedId == cat.id,
            onTap: () => onSelect(cat.id),
          );
        },
      ),
    );
  }

  String _iconForCategory(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('terraza')) return '🏠';
    if (n.contains('marisco') || n.contains('fish')) return '🐟';
    if (n.contains('carne') || n.contains('grill')) return '🥩';
    if (n.contains('vino')) return '🍷';
    if (n.contains('guachinche')) return '🌿';
    if (n.contains('desayuno')) return '☕';
    if (n.contains('mercado')) return '🛒';
    if (n.contains('tasca')) return '🍺';
    return '🍽';
  }
}

class _CategoryChip extends StatefulWidget {
  final String label;
  final String icon;
  final bool active;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.atlantico
                : context.brand.surface.withOpacity(0.55),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.active
                  ? AppColors.atlanticoClaro.withOpacity(0.6)
                  : context.brand.border,
              width: 1,
            ),
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: AppColors.atlantico.withOpacity(0.45),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: AppTextStyles.chipLabel(
                  size: 10,
                  color: widget.active
                      ? Colors.white
                      : AppColors.crema.withOpacity(0.7),
                ).copyWith(letterSpacing: 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
