import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/survey_in_app_choice.dart';
import 'package:guachinches/ui/pages/premios/premios_controllers.dart'
    show premiosErrorFromLegacyMessage;
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_in_app_presenter.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_vote_presenter.dart';

import 'survey_fakes.dart';

/// Las vistas de siempre siguen funcionando sobre el flujo v3.
class _View implements SurveyInAppView {
  final errors = <String>[];
  List<SurveyInAppChoice>? trad, mod;
  bool sent = false;

  @override
  void onSubmitSuccess() => sent = true;
  @override
  void setChoices({required List<SurveyInAppChoice> tradicionales, required List<SurveyInAppChoice> modernos}) {
    trad = tradicionales;
    mod = modernos;
  }

  @override
  void setLoading(bool loading) {}
  @override
  void setSubmitting(bool submitting) {}
  @override
  void showError(String message) => errors.add(message);
}

void main() {
  test('SurveyInAppPresenter delega en v3 y el 409 llega como el texto de siempre', () async {
    var now = DateTime.utc(2027, 2, 10);
    final repo = FakeSurveyRepo();
    final view = _View();
    final p = SurveyInAppPresenter(repo, view,
        core: SurveyVotePresenter(
          repository: repo,
          identity: identity(),
          clock: () => now,
        ));
    await p.initialize();
    expect(view.trad, isNotEmpty);
    now = now.add(const Duration(seconds: 10));

    repo.voteSteps.add(() => apiError(409, 'already_voted_this_business', details: {
          'conflicts': [
            {'category': kTrad, 'value': 'r-t1'}
          ]
        }));
    await p.submitVotes(tradicionalValue: 'r-t1', modernoValue: null);
    expect(view.errors.single, 'Ya has votado a este negocio anteriormente.');
    expect(premiosErrorFromLegacyMessage(view.errors.single), PremiosErrorKind.alreadyVoted);
    expect((await p.votedByDevice())[kTrad], contains('r-t1'));

    await p.submitVotes(tradicionalValue: 'r-t2', modernoValue: 'r-m1');
    expect(view.sent, isTrue);
  });
}
