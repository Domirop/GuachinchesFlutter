import 'package:flutter/material.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_in_app_page.dart';

class SurveyBanner extends StatelessWidget {
  final VoidCallback? onVoted;

  const SurveyBanner({Key? key, this.onVoted}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SurveyInAppPage(onVoted: onVoted)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: GlobalMethods.blueColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.how_to_vote_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premios Donde Comer Canarias 2026',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '¡Vota por tus guachinches favoritos!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
