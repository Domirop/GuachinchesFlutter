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
  GlassTabItem(icon: Icons.map_outlined, label: 'MAPA'),
  GlassTabItem(icon: Icons.play_circle_outline_rounded, label: 'VIDEOS'),
  GlassTabItem(icon: Icons.person_outline_rounded, label: 'PERFIL'),
];

/// Legacy constant kept so callers don't break. The classic
/// BottomNavigationBar now lives in the Scaffold's `bottomNavigationBar`
/// slot, so the body is automatically bounded above it — no extra padding
/// is needed for floating content.
const double kGlassTabBarReservedHeight = 0;

/// iOS 26-style liquid-glass tab bar.
/// - Heavy backdrop blur with vibrancy tint.
/// - Active tab uses a soft glow pill with the atlantico accent.
/// - Smooth spring transitions when switching tabs.
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
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        bottomInset > 0 ? bottomInset + 6 : 14,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.10),
                  Colors.white.withOpacity(0.04),
                ],
              ),
              color: AppColors.glassTab,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.04),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                  spreadRadius: -0.5,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(kGlassTabs.length, (i) {
                return Expanded(
                  child: _GlassTabButton(
                    item: kGlassTabs[i],
                    active: i == currentIndex,
                    onTap: () => onTap(i),
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

class _GlassTabButton extends StatelessWidget {
  final GlassTabItem item;
  final bool active;
  final VoidCallback onTap;

  const _GlassTabButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.atlantico,
                    AppColors.atlanticoOscuro,
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: active
              ? Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 0.8,
                )
              : null,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.atlantico.withOpacity(0.55),
                    blurRadius: 18,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.10),
                    blurRadius: 1,
                    offset: const Offset(0, 0.5),
                    spreadRadius: -0.5,
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: active ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                child: Icon(
                  item.icon,
                  size: 20,
                  color:
                      active ? Colors.white : context.brand.textMuted,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: AppTextStyles.ui(
                  size: 8,
                  weight: active ? FontWeight.w700 : FontWeight.w500,
                  color:
                      active ? Colors.white : context.brand.textMuted,
                ).copyWith(letterSpacing: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
