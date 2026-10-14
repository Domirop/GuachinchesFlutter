import 'package:flutter/material.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_my_votes_page.dart';

/// «Mis votos» desde las pantallas de siempre. Pinta el rediseño (tablero
/// EncuestaMisVotos) con el puesto real de cada sitio en el ranking (antes
/// se numeraba con la posición en la lista, `index + 1`).
class MyVotedRestaurants extends StatefulWidget {
  final List<SurveyResult> tradicionales;
  final List<SurveyResult> modernos;

  const MyVotedRestaurants({
    Key? key,
    required this.tradicionales,
    required this.modernos,
  }) : super(key: key);

  @override
  State<MyVotedRestaurants> createState() => _MyVotedRestaurantsState();
}

class _MyVotedRestaurantsState extends State<MyVotedRestaurants> {
  late final PremiosResultsController _c = PremiosResultsController(
    tradicionales: widget.tradicionales,
    modernos: widget.modernos,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PremiosMyVotesPage(controller: _c);
}
