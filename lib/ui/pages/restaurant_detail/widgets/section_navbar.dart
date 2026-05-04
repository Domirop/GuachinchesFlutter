import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';

class SectionNavbarDelegate extends SliverPersistentHeaderDelegate {
  static const double barHeight = 44;

  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onTap;

  SectionNavbarDelegate({
    required this.labels,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  double get minExtent => barHeight;

  @override
  double get maxExtent => barHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // El bar mide siempre 44px en el sliver, pero cuando está pinned al borde
    // superior extendemos el fondo HACIA ARRIBA por la altura del status bar
    // para cubrir la safe-area sin tocar el extent del sliver.
    final topInset = MediaQuery.of(context).padding.top;
    final isPinned = shrinkOffset > 0 || overlapsContent;
    final overflowTop = isPinned ? topInset : 0.0;

    final background = ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: context.brand.base.withOpacity(0.92),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.04)),
            ),
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -overflowTop,
          left: 0,
          right: 0,
          height: barHeight + overflowTop,
          child: background,
        ),
        SizedBox(
          height: barHeight,
          child: Row(
            children: List.generate(labels.length, (i) {
              final isActive = activeIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isActive
                              ? AppColors.atlantico
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[i].toUpperCase(),
                      style: AppTextStyles.ui(
                        size: 9,
                        weight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: isActive
                            ? AppColors.crema
                            : context.brand.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant SectionNavbarDelegate old) =>
      old.activeIndex != activeIndex || old.labels != labels;
}
