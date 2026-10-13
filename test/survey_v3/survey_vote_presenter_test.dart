import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/survey_v3.dart';
import 'package:guachinches/services/survey_integrity/device_identity_service.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_vote_presenter.dart';

import 'survey_fakes.dart';

void main() {
  late FakeSurveyRepo repo;
  late FakeAppCheck appCheck;
  late FakeLocalIdSource localIds;
  late DateTime now;
  late List<Duration> sleeps;
  late List<String> logs;
  DebugPrintCallback? originalDebugPrint;

  SurveyVotePresenter build({String platform = 'ios', String appVersion = '4.7.0'}) =>
      SurveyVotePresenter(
        repository: repo,
        identity: identity(platform: platform, localIds: localIds, appCheck: appCheck),
        appVersion: appVersion,
        clock: () => now,
        sleep: (d) async => sleeps.add(d),
        random: Random(1),
      );

  /// Carga, elige y deja pasar los 3 s mínimos.
  Future<SurveyVotePresenter> ready({
    String platform = 'ios',
    Map<String, String> picks = const {kTrad: 'r-t1', kMod: 'r-m1'},
  }) async {
    final p = build(platform: platform);
    await p.load();
    expect(p.state.stage, SurveyVoteStage.ready);
    picks.forEach(p.select);
    now = now.add(const Duration(seconds: 5));
    return p;
  }

  setUp(() {
    repo = FakeSurveyRepo();
    appCheck = FakeAppCheck();
    localIds = FakeLocalIdSource();
    now = DateTime.utc(2027, 2, 10, 12);
    sleeps = [];
    logs = [];
    originalDebugPrint = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) => logs.add(m ?? '');
  });

  tearDown(() => debugPrint = originalDebugPrint!);

  group('carga', () {
    test('my-votes con token de App Check e identidad; candidatos sin los ya votados', () async {
      repo.mine = const SurveyMyVotes(status: SurveyDeviceStatus.active, voted: {
        kMod: ['r-both'],
      });
      final p = build();
      await p.load();

      expect(p.state.stage, SurveyVoteStage.ready);
      expect(appCheck.activations, 1);
      final enroll = repo.mineReads.single;
      expect(enroll.token, '${kTokenPrefix}1');
      expect(enroll.body, {'platform': 'ios', 'localIdHash': 'a' * 64});
      // voteScope=business: un negocio votado sale de las dos categorías.
      expect(p.state.candidates[kTrad]!.map((c) => c.value), isNot(contains('r-both')));
      expect(p.state.candidates[kMod]!.map((c) => c.value), ['r-m1']);
      expect(p.state.voted[kMod], {'r-both'});
    });

    test('sin token de App Check (simulador, sin App Attest / Play) → unsupported tipado', () async {
      appCheck.activateError = const SurveyIntegrityException(SurveyIntegrityError.unsupported);
      final p = build();
      await p.load();
      expect(p.state.stage, SurveyVoteStage.unsupported);
      expect(p.state.failure, isA<SurveyDeviceUnsupported>());
      expect(repo.mineReads, isEmpty, reason: 'sin token no hay petición');
    });

    test('App Check rechazado en el móvil → aviso de integridad y reintentable', () async {
      appCheck.tokenErrors.add(const SurveyIntegrityException(SurveyIntegrityError.failed));
      final p = build();
      await p.load();
      expect(p.state.stage, SurveyVoteStage.failed);
      final f = p.state.failure as SurveyIntegrityFailed;
      expect(f.code, 'client');
      expect(f.retryable, isTrue);
      await p.retry();
      expect(p.state.stage, SurveyVoteStage.ready);
    });

    test('versión por debajo de minAppVersion → upgradeRequired sin pedir token', () async {
      final p = build(appVersion: '4.6.0');
      await p.load();
      expect(p.state.stage, SurveyVoteStage.upgradeRequired);
      expect((p.state.failure as SurveyUpgradeRequired).minAppVersion, '4.7.0');
      expect(appCheck.tokens, isEmpty);
    });

    test('identidad bloqueada en my-votes → stage blocked; sin edición protegida → closed', () async {
      repo.mine = const SurveyMyVotes(status: SurveyDeviceStatus.blocked);
      final p = build();
      await p.load();
      expect(p.state.stage, SurveyVoteStage.blocked);
      repo.editionSteps.add(() => apiError(404, 'edition_not_found'));
      await p.load();
      expect(p.state.stage, SurveyVoteStage.closed);
    });

    test('edición cerrada y próxima', () async {
      repo.currentEdition = edition(status: SurveyEditionStatus.closed);
      final p = build();
      await p.load();
      expect(p.state.stage, SurveyVoteStage.closed);
      repo.currentEdition = edition(status: SurveyEditionStatus.upcoming);
      await p.load();
      expect(p.state.stage, SurveyVoteStage.upcoming);
    });

    test('red al leer la edición: backoff (no lleva token) y luego carga', () async {
      repo.editionSteps.add(() => throw const SurveyNetworkException());
      final p = build();
      await p.load();
      expect(p.state.stage, SurveyVoteStage.ready);
      expect(sleeps, [const Duration(milliseconds: 600)]);
    });
  });

  group('voto', () {
    test('201: votos aceptados con token nuevo y los votados salen de la lista', () async {
      final p = await ready();
      await p.submit();
      expect(p.state.stage, SurveyVoteStage.sent);
      expect(p.state.accepted, const [
        SurveyVoteSelection(kMod, 'r-m1'),
        SurveyVoteSelection(kTrad, 'r-t1'),
      ]);
      expect(p.state.selection, isEmpty);
      expect(p.state.candidates[kTrad]!.map((c) => c.value), isNot(contains('r-t1')));
      final vote = repo.votes.single;
      expect(vote.token, '${kTokenPrefix}2', reason: 'otro token, no el de my-votes');
      expect(vote.body, {
        'platform': 'ios',
        'localIdHash': 'a' * 64,
        'votes': [
          {'category': kMod, 'value': 'r-m1'},
          {'category': kTrad, 'value': 'r-t1'},
        ],
      });
      p.voteAgain();
      expect(p.state.stage, SurveyVoteStage.ready);
    });

    test('409 con conflictos: categoría y value, quitados de la selección y marcados', () async {
      final p = await ready();
      repo.voteSteps.add(() => apiError(409, 'already_voted_this_business', details: {
            'conflicts': [
              {'category': kMod, 'value': 'r-m1'}
            ]
          }));
      await p.submit();

      expect(p.state.stage, SurveyVoteStage.ready);
      final f = p.state.failure as SurveyAlreadyVoted;
      expect(f.conflicts, const [SurveyVoteSelection(kMod, 'r-m1')]);
      expect(p.state.conflicts, f.conflicts);
      expect(p.state.isConflict(kMod, 'r-m1'), isTrue);
      expect(p.state.selection, {kTrad: 'r-t1'}, reason: 'el otro voto sigue en la papeleta');
      expect(p.state.voted[kMod], contains('r-m1'));
      expect(f.retryable, isFalse);
      expect(repo.votes, hasLength(1), reason: 'un 409 no se reintenta');
    });

    test('403 de App Check (integrity_failed) → error tipado, votos conservados', () async {
      final p = await ready();
      repo.voteSteps.add(() => apiError(403, 'integrity_failed', details: {'reason': 'app_check_invalid'}));
      await p.submit();
      expect(p.state.stage, SurveyVoteStage.ready);
      final f = p.state.failure as SurveyIntegrityFailed;
      expect(f.code, 'integrity_failed');
      expect(f.reason, 'app_check_invalid');
      expect(p.state.selection, hasLength(2));
      expect(repo.votes, hasLength(1));
    });

    test('token ya consumido (app_check_replayed) → un reintento con token nuevo, sin duplicar', () async {
      final p = await ready();
      repo.voteSteps.add(() => apiError(403, 'integrity_failed', details: {'reason': 'app_check_replayed'}));
      await p.submit();
      expect(p.state.stage, SurveyVoteStage.sent);
      expect(repo.votes, hasLength(2));
      expect(repo.votes.map((v) => v.token).toSet(), hasLength(2),
          reason: 'nunca se reenvía con el mismo token');
    });

    test('token consumido dos veces → se rinde tras un solo reintento', () async {
      final p = await ready();
      for (var i = 0; i < 2; i++) {
        repo.voteSteps.add(() => apiError(403, 'integrity_failed', details: {'reason': 'app_check_replayed'}));
      }
      await p.submit();
      expect(p.state.stage, SurveyVoteStage.ready);
      expect((p.state.failure as SurveyIntegrityFailed).reason, 'app_check_replayed');
      expect(repo.votes, hasLength(2));
    });

    test('426 → pantalla de actualizar', () async {
      final p = await ready();
      repo.voteSteps.add(() => apiError(426, 'upgrade_required', details: {
            'minAppVersion': {'ios': '4.8.0', 'android': '4.8.0'}
          }));
      await p.submit();
      expect(p.state.stage, SurveyVoteStage.upgradeRequired);
      expect((p.state.failure as SurveyUpgradeRequired).minAppVersion, '4.8.0');
    });

    test('429 → rate limited con Retry-After, sin reenviar solo', () async {
      final p = await ready();
      repo.voteSteps.add(() => apiError(429, 'rate_limited', retryAfter: const Duration(seconds: 60)));
      await p.submit();
      expect(p.state.stage, SurveyVoteStage.ready);
      expect((p.state.failure as SurveyRateLimited).retryAfter, const Duration(seconds: 60));
      expect(p.state.failure!.retryable, isTrue);
      expect(repo.votes, hasLength(1));
      expect(sleeps, isEmpty);
    });

    test('device_blocked / edition_closed → su stage', () async {
      for (final (code, stage) in [
        ('device_blocked', SurveyVoteStage.blocked),
        ('edition_closed', SurveyVoteStage.closed),
      ]) {
        repo = FakeSurveyRepo();
        final p = await ready();
        repo.voteSteps.add(() => apiError(403, code));
        await p.submit();
        expect(p.state.stage, stage, reason: code);
      }
    });

    test('503, red y 500: «Reintentar» siempre con un token nuevo', () async {
      final p = await ready();
      repo.voteSteps.add(() => apiError(503, 'integrity_unavailable', retryAfter: const Duration(seconds: 30)));
      await p.submit();
      expect((p.state.failure as SurveyVerificationUnavailable).retryAfter, const Duration(seconds: 30));
      repo.voteSteps.add(() => throw const SurveyNetworkException());
      await p.retry();
      expect(p.state.failure, isA<SurveyNetworkFailure>());
      repo.voteSteps.add(() => apiError(500, 'http_500'));
      await p.retry();
      expect((p.state.failure as SurveyServerFailure).status, 500);
      await p.retry();
      expect(p.state.stage, SurveyVoteStage.sent);
      expect(repo.votes, hasLength(4));
      expect(repo.votes.map((v) => v.token).toSet(), hasLength(4));
    });

    test('sin token al votar → error tipado y no se envía nada', () async {
      final p = await ready();
      appCheck.tokenErrors.add(const SurveyIntegrityException(SurveyIntegrityError.network));
      await p.submit();
      expect(p.state.failure, isA<SurveyNetworkFailure>());
      expect(repo.votes, isEmpty);
    });

    test('modo avión a mitad: el voto entró, el reintento da 409 de todo → éxito', () async {
      final p = await ready();
      repo.voteSteps
        ..add(() => throw const SurveyNetworkException(maybeDelivered: true))
        ..add(() => apiError(409, 'already_voted_this_business', details: {
              'conflicts': [
                {'category': kMod, 'value': 'r-m1'},
                {'category': kTrad, 'value': 'r-t1'},
              ]
            }));
      await p.submit();
      expect(p.state.failure, isA<SurveyNetworkFailure>());
      expect(p.state.selection, hasLength(2), reason: 'los votos siguen en la papeleta');
      await p.retry();
      expect(p.state.stage, SurveyVoteStage.sent);
    });

    test('sin elegir y demasiado rápido: no se pide token', () async {
      final p = build();
      await p.load();
      await p.submit();
      expect(p.state.failure, isA<SurveyNoSelection>());
      p.select(kTrad, 'r-t1');
      await p.submit();
      expect(p.state.failure, isA<SurveyTooFast>());
      expect(appCheck.tokens, hasLength(1), reason: 'solo el de my-votes');
    });

    test('Android: mismo flujo con platform=android', () async {
      final p = await ready(platform: 'android');
      await p.submit();
      expect(p.state.stage, SurveyVoteStage.sent);
      expect(repo.mineReads.single.body['platform'], 'android');
      expect(repo.votes.single.body['platform'], 'android');
    });
  });

  group('logs', () {
    test('ningún token ni identificador llega a AppLogger (Crashlytics)', () async {
      localIds = FakeLocalIdSource('f' * 64);
      final p = await ready();
      repo.voteSteps
        ..add(() => apiError(409, 'already_voted_this_business', details: {
              'conflicts': [
                {'category': kMod, 'value': 'r-m1'}
              ]
            }))
        ..add(() => apiError(403, 'integrity_failed', details: {'reason': 'app_check_replayed'}))
        ..add(() => apiError(403, 'integrity_failed', details: {'reason': 'app_check_invalid'}))
        ..add(() => throw const SurveyNetworkException(maybeDelivered: true));
      await p.submit(); // 409
      await p.submit(); // replayed → reintento → 403
      await p.retry(); // red
      await p.retry(); // 201
      expect(p.state.stage, SurveyVoteStage.sent);

      expect(logs, isNotEmpty, reason: 'sí se registra el flujo');
      final all = logs.join('\n');
      for (final secret in [kTokenPrefix, 'f' * 64]) {
        expect(all, isNot(contains(secret)), reason: 'se ha registrado $secret');
      }
      expect(p.state.toString(), isNot(contains('f' * 64)));
    });
  });
}
