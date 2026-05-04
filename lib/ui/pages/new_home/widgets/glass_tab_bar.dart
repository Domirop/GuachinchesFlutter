import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';

class GlassTabItem {
  final IconData icon;
  final String label;

  const GlassTabItem({required this.icon, required this.label});
}

const kGlassTabs = [
  GlassTabItem(icon: Icons.explore_outlined, label: 'EXPLORA'),
  GlassTabItem(icon: Icons.list_rounded, label: 'LISTAS'),
  GlassTabItem(icon: Icons.search_rounded, label: 'BUSCAR'),
  GlassTabItem(icon: Icons.favorite_border_rounded, label: 'GUARDADO'),
  GlassTabItem(icon: Icons.person_outline_rounded, label: 'PERFIL'),
];

class GlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        14, 0, 14,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.glassTab,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 24,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(kGlassTabs.length, (i) {
                final tab = kGlassTabs[i];
                final active = i == currentIndex;
                return GestureDetector(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    padding: EdgeInsets.symmetric(
                      horizontal: active ? 12 : 8,
                      vertical: 6,
                    ),
                    decoration: active
                        ? BoxDecoration(
                            color: AppColors.atlantico.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.atlantico.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          )
                        : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 16,
                          color: active
                              ? Colors.white
                              : context.brand.textMuted,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: AppTextStyles.ui(
                            size: 7,
                            weight: FontWeight.w500,
                            color: active
                                ? Colors.white
                                : context.brand.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
