import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/globalMethods.dart';

/// Compact horizontal pill chip for a category.
/// Replaces the old CategoryImageCard (240×150) with a 56px-tall pill
/// that shows an SVG icon + label — saves ~76px of vertical scroll space.
class CategoryPillChip extends StatelessWidget {
  final ModelCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryPillChip({
    Key? key,
    required this.category,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? GlobalMethods.blueColor : GlobalMethods.bgColorFilter,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? GlobalMethods.blueColor
                : Colors.white.withOpacity(0.22),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category.iconUrl.isNotEmpty) ...[
              SvgPicture.network(
                category.iconUrl,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                placeholderBuilder: (_) =>
                    const Icon(Icons.restaurant, size: 18, color: Colors.white70),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              category.nombre,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontFamily: 'SF Pro Display',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
