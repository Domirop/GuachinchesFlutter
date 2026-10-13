import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';

/// Controlador de flujo en memoria: las vistas solo ven el estado.
class FakeFlow extends PremiosFlowController {
  PremiosFlowState _s;
  int submits = 0;
  FakeFlow(this._s);

  @override
  PremiosFlowState get state => _s;

  void emit(PremiosFlowState s) {
    _s = s;
    notifyListeners();
  }

  @override
  Future<void> load() async {}

  @override
  void pick(PremiosCategory category, PremiosCandidate candidate) {
    final p = Map.of(_s.picks);
    p[category] == candidate ? p.remove(category) : p[category] = candidate;
    emit(_s.copyWith(picks: p));
  }

  @override
  Future<void> submit() async => submits++;

  @override
  Future<void> voteAgain() async {}
}

class FakeRanking extends PremiosRankingController {
  @override
  final PremiosRankingState state;
  FakeRanking(this.state);

  @override
  Future<void> refresh() async {}
}

PremiosRankEntry entry(String name, int votes, int rank,
        {bool tied = false, bool mine = false, String muni = 'La Orotava'}) =>
    PremiosRankEntry(
      id: name,
      name: name,
      municipio: muni,
      photoUrl: null,
      votes: votes,
      rank: rank,
      tied: tied,
      mine: mine,
    );

/// App con tema día/noche y movimiento reducido opcional.
Widget app(Widget home, {bool dark = false, bool reduce = false}) =>
    MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduce,
          padding: const EdgeInsets.only(top: 62, bottom: 34),
        ),
        child: child!,
      ),
      home: home,
    );

/// Pantalla de móvil grande (la fuente de los tests, Ahem, es más ancha
/// que SF y desbordaría a 402).
void phone(dynamic tester) {
  tester.view.physicalSize = const Size(440 * 3, 956 * 3);
  tester.view.devicePixelRatio = 3.0;
}
