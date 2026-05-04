import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';

class IslandChip {
  final String id;
  final String key;   // 'TF', 'GC', 'LZ', 'FV', 'LP', 'GO', 'EH'
  final String label;
  final int count;

  const IslandChip({
    required this.id,
    required this.key,
    required this.label,
    required this.count,
  });
}

/// Fila horizontal de chips de isla.
class IslandChipRow extends StatelessWidget {
  final List<IslandChip> islands;
  final String selectedId;
  final ValueChanged<IslandChip> onSelect;

  const IslandChipRow({
    super.key,
    required this.islands,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: islands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = islands[i];
          final active = chip.id == selectedId;
          return _IslandChipTile(chip: chip, active: active, onTap: () => onSelect(chip));
        },
      ),
    );
  }
}

class _IslandChipTile extends StatefulWidget {
  final IslandChip chip;
  final bool active;
  final VoidCallback onTap;

  const _IslandChipTile({
    required this.chip,
    required this.active,
    required this.onTap,
  });

  @override
  State<_IslandChipTile> createState() => _IslandChipTileState();
}

class _IslandChipTileState extends State<_IslandChipTile> {
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.active ? AppColors.atlantico : context.brand.surface,
            borderRadius: BorderRadius.circular(12),
            border: widget.active
                ? null
                : Border.all(color: context.brand.border),
            boxShadow: widget.active
                ? [BoxShadow(
                    color: AppColors.atlantico.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.chip.key,
                style: AppTextStyles.chipLabel(
                  size: 11,
                  color: widget.active
                      ? Colors.white
                      : context.brand.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.chip.count} sitios',
                style: AppTextStyles.muted(
                  size: 9,
                  color: widget.active
                      ? Colors.white.withOpacity(0.75)
                      : context.brand.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
