import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/Visit.dart';

class TicketCardWidget extends StatelessWidget {
  final Visit visit;

  const TicketCardWidget({super.key, required this.visit});

  static bool shouldRender(Visit? v) =>
      v != null &&
      (v.myTicket?.isNotEmpty == true || v.priceApprox != null);

  @override
  Widget build(BuildContext context) {
    String title;
    String? subtitle;
    if (visit.myTicket?.isNotEmpty == true) {
      title = visit.myTicket!;
      subtitle = visit.extraText;
    } else if (visit.priceApprox != null) {
      final perTwo = (visit.priceApprox! * 2);
      final perTwoStr = perTwo % 1 == 0
          ? perTwo.toInt().toString()
          : perTwo.toStringAsFixed(2);
      title = '$perTwoStr€ PARA DOS';
      subtitle = visit.extraText;
    } else {
      title = visit.extraText ?? '';
      subtitle = null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2A1C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sol.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.sol.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '€',
              style: TextStyle(
                fontFamily: 'Oswald',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.sol,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTextStyles.displaySection(
                    size: 13,
                    color: AppColors.sol,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.ui(
                      size: 11,
                      color: AppColors.crema.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
