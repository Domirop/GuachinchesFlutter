import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';

class DetailCtas extends StatelessWidget {
  final VoidCallback onDirections;
  final VoidCallback? onCall;
  final VoidCallback? onWeb;

  const DetailCtas({
    super.key,
    required this.onDirections,
    this.onCall,
    this.onWeb,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.atlantico,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                elevation: 0,
              ),
              onPressed: onDirections,
              child: Text(
                'CÓMO LLEGAR',
                style: AppTextStyles.displaySection(size: 11)
                    .copyWith(color: Colors.white, letterSpacing: 1.0),
              ),
            ),
          ),
          if (onCall != null) ...[
            const SizedBox(width: 7),
            _IconCTA(icon: Icons.phone_outlined, onTap: onCall!),
          ],
          if (onWeb != null) ...[
            const SizedBox(width: 7),
            _IconCTA(icon: Icons.link, onTap: onWeb!),
          ],
        ],
      ),
    );
  }
}

class _IconCTA extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconCTA({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: context.brand.surface,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.crema),
      ),
    );
  }
}
