import 'package:flutter/material.dart';
import 'package:guachinches/globalMethods.dart';

/// Reusable section header with title + optional "Ver todos →" CTA.
/// Used across Home (Cerca de ti, Categorías, Top, Favoritos, Videos).
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final String actionLabel;

  const SectionHeader({
    Key? key,
    required this.title,
    this.onTap,
    this.actionLabel = 'Ver todos →',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'SF Pro Display',
            ),
          ),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 14,
                  color: GlobalMethods.blueColor,
                  fontFamily: 'SF Pro Display',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
