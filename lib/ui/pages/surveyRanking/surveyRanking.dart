import 'package:flutter/material.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_ranking_page.dart';

/// Ranking de la encuesta desde las pantallas de siempre. Pinta el
/// rediseño (tablero EncuestaRanking) con los resultados que ya traía el
/// Inicio viejo y recarga con [SurveyRankingPresenter].
class SurveyRanking extends StatefulWidget {
  final List<SurveyResult> guachinchesTradicionales;
  final List<SurveyResult> guachinchesModernos;
  final List<Restaurant> allRestaurants;
  final VoidCallback onRefresh;
  final bool isInitialTraditional;

  const SurveyRanking({
    Key? key,
    required this.guachinchesTradicionales,
    required this.guachinchesModernos,
    required this.isInitialTraditional,
    required this.allRestaurants,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<SurveyRanking> createState() => _SurveyRankingState();
}

class _SurveyRankingState extends State<SurveyRanking> {
  late final LegacyPremiosRankingController _c = LegacyPremiosRankingController(
    restaurants: widget.allRestaurants,
    tradicionales: widget.guachinchesTradicionales,
    modernos: widget.guachinchesModernos,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PremiosRankingPage(
        controller: _c,
        initialCategory: widget.isInitialTraditional
            ? PremiosCategory.tradicional
            : PremiosCategory.moderno,
        onRefresh: widget.onRefresh,
      );
}
