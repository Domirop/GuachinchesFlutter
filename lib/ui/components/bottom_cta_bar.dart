import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';

/// Anchored bottom action bar used by detail screens.
/// Primary button (atlantico) + optional secondary icon button.
class BottomCtaBar extends StatelessWidget {
  final VoidCallback onPrimary;
  final String primaryLabel;
  final VoidCallback? onSecondary;
  final IconData secondaryIcon;

  const BottomCtaBar({
    super.key,
    required this.onPrimary,
    this.primaryLabel = 'CÓMO LLEGAR ›',
    this.onSecondary,
    this.secondaryIcon = Icons.ios_share,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: context.brand.base,
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottom + 10),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.atlantico,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: onPrimary,
              child: Text(
                primaryLabel,
                style: AppTextStyles.displaySection(size: 11)
                    .copyWith(color: Colors.white, letterSpacing: 1.0),
              ),
            ),
          ),
          if (onSecondary != null) ...[
            const SizedBox(width: 8),
            _SecondaryBtn(icon: secondaryIcon, onTap: onSecondary!),
          ],
        ],
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: context.brand.surface,
          border: Border.all(color: context.brand.borderStrong),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: context.brand.textPrimary),
      ),
    );
  }
}
