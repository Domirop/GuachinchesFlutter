// TEMPORAL: galería para capturas con datos simulados. NO COMMITEAR.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/theme/theme_cubit.dart';
import 'package:guachinches/data/model/survey_v3.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart';
import 'package:guachinches/ui/pages/premios/premios_entry_page.dart';
import 'package:guachinches/ui/pages/premios/premios_home.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/premios/premios_review_page.dart';
import 'package:guachinches/ui/pages/premios/premios_vote_page.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

class _F extends PremiosFlowController {
  PremiosFlowState s;
  _F(this.s);
  @override
  PremiosFlowState get state => s;
  @override
  Future<void> load() async {}
  @override
  void pick(PremiosCategory c, PremiosCandidate x) {}
  @override
  Future<void> submit() async {}
  @override
  Future<void> retry() async {}
  @override
  Future<void> voteAgain() async {}
}

class _R extends PremiosRankingController {
  @override
  final PremiosRankingState state;
  _R(this.state);
  @override
  Future<void> refresh() async {}
}

PremiosRankEntry _e(String n, int v, int r, {bool t = false, bool m = false}) =>
    PremiosRankEntry(
        id: n,
        name: n,
        municipio: '',
        photoUrl: null,
        votes: v,
        rank: r,
        tied: t,
        mine: m);

PremiosRankingState _rk(bool mine) =>
    PremiosRankingState(load: PremiosLoad.ready, tradicional: [
      _e('Bodega Zacatín (Guachinche El Churrasco)', 7, 1),
      _e('Guachinche Don Trino', 6, 2, t: true),
      _e('Guachinche La Cuadra (La Victoria)', 6, 2, t: true),
      _e('Guachinche Casa Pepe', 5, 4, m: mine),
    ], moderno: [
      _e('Casa Doña Vidalina', 4, 1, t: true),
      _e('Tasca Corral del Chivo', 4, 1, t: true),
      _e('Guachinche El Fogón', 3, 3),
      _e('Tasca Las Dehesas', 1, 12, m: mine),
    ]);

const _t = PremiosCandidate(value: '1', name: 'Guachinche Nunca Es Lejos');
const _m = PremiosCandidate(value: '2', name: 'Tasca Las Dehesas');

class PremiosPreviewTmp extends StatelessWidget {
  const PremiosPreviewTmp({super.key});

  @override
  Widget build(BuildContext context) {
    void go(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    void edition(DateTime end, {SurveyEditionStatus? st}) =>
        PremiosEditionStore.instance.set(PremiosEdition(
            votingEndsAt: end, status: st ?? SurveyEditionStatus.open, id: 1));
    Widget home(PremiosLiveVariant v, PremiosRankingState r) => Builder(
        builder: (context) => Scaffold(
              backgroundColor: GmColors.of(context).canvas,
              body:
                  ListView(padding: const EdgeInsets.only(top: 60), children: [
                PremiosLiveSection(
                  variant: v,
                  ranking: r,
                  totalVotes: 130,
                  remaining:
                      v == PremiosLiveVariant.closed ? '' : 'Quedan 12 días',
                  onVote: () {},
                  onRanking: () {},
                ),
              ]),
            ));
    PremiosFlowState gate(PremiosGate g, {String? min}) =>
        PremiosFlowState(load: PremiosLoad.ready, gate: g, minAppVersion: min);
    PremiosFlowState err(PremiosErrorKind k) => PremiosFlowState(
        load: PremiosLoad.ready,
        picks: const {
          PremiosCategory.tradicional: _t,
          PremiosCategory.moderno: _m
        },
        error: PremiosError(k));
    final items = <String, VoidCallback>{
      'TEMA día/noche': () => context.read<ThemeCubit>().toggle(),
      'modulo-sin-votar': () {
        edition(DateTime.utc(2026, 10, 26, 23, 59));
        go(home(PremiosLiveVariant.notVoted, _rk(false)));
      },
      'modulo-ya-votaste': () => go(home(PremiosLiveVariant.voted, _rk(true))),
      'modulo-cerrada': () => go(home(PremiosLiveVariant.closed, _rk(true))),
      'entrada-unsupported': () =>
          go(PremiosEntryPage(controller: _F(gate(PremiosGate.unsupported)))),
      'entrada-blocked': () =>
          go(PremiosEntryPage(controller: _F(gate(PremiosGate.blocked)))),
      'entrada-upgrade': () => go(PremiosEntryPage(
          controller: _F(gate(PremiosGate.upgradeRequired, min: '4.8.0')))),
      'entrada-upcoming': () {
        PremiosEditionStore.instance.set(PremiosEdition(
            votingStartsAt: DateTime.utc(2027, 2, 1),
            votingEndsAt: DateTime.utc(2027, 3, 20, 23, 59),
            status: SurveyEditionStatus.upcoming));
        go(PremiosEntryPage(controller: _F(gate(PremiosGate.upcoming))));
      },
      'entrada-cerrada': () {
        edition(DateTime.utc(2026, 3, 20, 23, 59),
            st: SurveyEditionStatus.closed);
        go(PremiosEntryPage(controller: _F(gate(PremiosGate.closed))));
      },
      'entrada-sin-red': () {
        edition(DateTime.utc(2026, 10, 26, 23, 59));
        go(PremiosEntryPage(
            controller: _F(const PremiosFlowState(
                load: PremiosLoad.error,
                loadError: PremiosErrorKind.network))));
      },
      'votar-verificacion': () => go(PremiosVotePage(
          controller: _F(const PremiosFlowState(
              load: PremiosLoad.error,
              loadError: PremiosErrorKind.verificationUnavailable)))),
      'rev-403': () => go(PremiosReviewPage(
          controller: _F(err(PremiosErrorKind.deviceUnverified)))),
      'rev-503': () => go(PremiosReviewPage(
          controller: _F(err(PremiosErrorKind.verificationUnavailable)))),
      'rev-422': () => go(PremiosReviewPage(
          controller: _F(err(PremiosErrorKind.invalidOption)))),
      'rev-429': () => go(
          PremiosReviewPage(controller: _F(err(PremiosErrorKind.rateLimited)))),
      'rev-409-fila': () => go(PremiosReviewPage(
          controller: _F(const PremiosFlowState(
              load: PremiosLoad.ready,
              picks: {PremiosCategory.moderno: _m},
              conflicts: {PremiosCategory.tradicional: _t},
              error: PremiosError(PremiosErrorKind.alreadyVoted,
                  category: PremiosCategory.tradicional, value: '1'))))),
    };
    return Scaffold(
      body: ListView(padding: const EdgeInsets.only(top: 60), children: [
        for (final e in items.entries)
          ListTile(dense: true, title: Text(e.key), onTap: e.value),
      ]),
    );
  }
}
