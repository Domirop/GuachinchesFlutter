import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/local/http_cache_store.dart';
import 'package:guachinches/data/model/survey_v3.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'survey_fakes.dart';

const _token = '${kTokenPrefix}HTTP';
const _local = 'c0ffee00c0ffee00c0ffee00c0ffee00c0ffee00c0ffee00c0ffee00c0ffee00';

void main() {
  late List<String> logs;
  late List<http.Request> requests;
  DebugPrintCallback? original;

  setUpAll(() => dotenv.testLoad(fileInput: 'ENDPOINT_V2=https://fake.test/v2/\n'));

  setUp(() {
    logs = [];
    requests = [];
    original = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) => logs.add(m ?? '');
  });
  tearDown(() => debugPrint = original!);

  HttpRemoteRepository repo(Future<http.Response> Function(http.Request) handler) =>
      HttpRemoteRepository(
        MockClient((r) {
          requests.add(r);
          return handler(r);
        }),
        cache: HttpCacheStore.withStorage(InMemoryCacheStorage()),
        backgroundEnabled: false,
      );

  http.Response json_(Object body, int status, {Map<String, String> headers = const {}}) =>
      http.Response(jsonEncode(body), status,
          headers: {'content-type': 'application/json', ...headers});

  test('rutas v3, cuerpo tal cual y token en X-Firebase-AppCheck; nada de eso en los logs', () async {
    final r = repo((req) async {
      if (req.url.path.endsWith('/editions/current')) {
        return json_({
          'editionId': 2,
          'label': 'Premios',
          'status': 'open',
          'integrityPolicy': 'attested',
          'voteScope': 'business',
          'minAppVersion': {'ios': '4.7.0', 'android': '4.7.0'},
          'categories': [kTrad, kMod],
        }, 200);
      }
      if (req.url.path.endsWith('/my-votes')) {
        return json_({
          'status': 'active',
          'voted': {kTrad: ['r-1'], kMod: []},
        }, 200);
      }
      return json_({
        'accepted': [
          {'category': kTrad, 'value': 'r-2'}
        ],
        'voted': {kTrad: ['r-1', 'r-2']}
      }, 201);
    });

    final ed = await r.getCurrentSurveyEdition();
    expect(ed.editionId, 2);
    expect(ed.minAppVersion['ios'], '4.7.0');

    final body = {'platform': 'ios', 'localIdHash': _local};
    final d = await r.getMySurveyVotes(2, body, appCheckToken: _token);
    expect(requests.last.url.path, '/v2/surveys/v3/editions/2/my-votes');
    expect(requests.last.headers[kAppCheckHeader], _token);
    expect(jsonDecode(requests.last.body), body);
    expect(d.status, SurveyDeviceStatus.active);
    expect(d.voted[kTrad], ['r-1']);

    final receipt = await r.submitSurveyVotesV3(2, {...body, 'votes': []}, appCheckToken: _token);
    expect(requests.last.url.path, '/v2/surveys/v3/editions/2/votes');
    expect(requests.last.headers[kAppCheckHeader], _token);
    expect(receipt.accepted.single, const SurveyVoteSelection(kTrad, 'r-2'));

    final all = logs.join('\n');
    for (final s in [_token, _local]) {
      expect(all, isNot(contains(s)), reason: 'log con $s');
    }
    expect(all, contains('POST editions/:id/votes → 201'));
  });

  test('errores tipados: 409 conflictos, 403 motivo, 426, 429 Retry-After', () async {
    final responses = [
      json_({
        'error': 'already_voted_this_business',
        'message': 'device dev-SENSITIVE',
        'details': {
          'conflicts': [
            {'category': kMod, 'value': 'r-9'}
          ]
        }
      }, 409),
      json_({'error': 'integrity_failed', 'details': {'reason': 'app_check_replayed'}}, 403),
      http.Response('<html>Upgrade</html>', 426),
      json_({'error': 'rate_limited'}, 429, headers: {'retry-after': '60'}),
    ];
    final r = repo((_) async => responses.removeAt(0));

    Future<SurveyApiException> call() async {
      try {
        await r.submitSurveyVotesV3(2, const {}, appCheckToken: _token);
      } on SurveyApiException catch (e) {
        return e;
      }
      fail('no lanzó');
    }

    final e409 = await call();
    expect(e409.status, 409);
    expect(e409.conflicts, const [SurveyVoteSelection(kMod, 'r-9')]);
    final e403 = await call();
    expect(e403.code, 'integrity_failed');
    expect(e403.reason, 'app_check_replayed');
    final e426 = await call();
    expect(e426.code, 'upgrade_required');
    final e429 = await call();
    expect(e429.retryAfter, const Duration(seconds: 60));

    final all = logs.join('\n');
    expect(all, isNot(contains(_token)));
    expect(all, isNot(contains('dev-SENSITIVE')), reason: 'el message del servidor no se registra');
  });

  test('red: SocketException → SurveyNetworkException (un POST puede haber llegado)', () async {
    final r = repo((_) async => throw const SocketException('sin red'));
    await expectLater(
        r.submitSurveyVotesV3(2, const {}, appCheckToken: _token),
        throwsA(isA<SurveyNetworkException>().having((e) => e.maybeDelivered, 'maybeDelivered', isTrue)));
    await expectLater(r.getCurrentSurveyEdition(),
        throwsA(isA<SurveyNetworkException>().having((e) => e.maybeDelivered, 'maybeDelivered', isFalse)));
  });

  test('candidatos por edición, sin survey_schema_id fijo', () async {
    final r = repo((_) async => json_([
          {'value': 'r-1', 'text': 'UNO'}
        ], 200));
    final list = await r.getSurveyEditionChoices(2, kTrad);
    expect(requests.single.url.path, '/v2/category-restaurants/surveyjs/2/$kTrad');
    expect(list.single.value, 'r-1');
  });
}
