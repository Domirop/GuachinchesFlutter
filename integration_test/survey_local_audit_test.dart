import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/model/survey_v3.dart';
import 'package:guachinches/services/survey_integrity/device_identity_service.dart';
import 'package:guachinches/services/survey_integrity/survey_integrity.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

/// Only the standalone localhost audit backend. No production app bootstrap.
/// Real native Keychain/SSAID + production repository + synthetic attestation.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native identity and HTTP vote survive a client recreation',
      (tester) async {
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    dotenv.testLoad(fileInput: 'ENDPOINT_V2=http://$host:3829/');
    final local =
        Platform.isIOS ? KeychainLocalIdSource() : SsaidLocalIdSource();
    final ids = await Future.wait(List.generate(20, (_) => local.localId()));
    expect(ids.map((id) => id.hash).toSet().length, 1);
    expect(SurveyLocalId.isValid(ids.first.hash), isTrue);
    final reopened =
        Platform.isIOS ? KeychainLocalIdSource() : SsaidLocalIdSource();
    expect((await reopened.localId()).hash, ids.first.hash);

    final identity = DeviceIdentityService(
      localIds: reopened,
      appCheck: FakeAppCheckTokenSource(appId: '1:111:ios:aaa'),
      platform: Platform.isIOS ? 'ios' : 'android',
    );
    await identity.ensureReady();
    final client = http.Client();
    // Explicit local HTTP client: this test does not assert TLS/pinning.
    final repository = HttpRemoteRepository(
      client,
      surveyClient: client,
      backgroundEnabled: false,
    );
    final edition = await repository.getCurrentSurveyEdition();
    expect(edition.editionId, 2);
    const selection = SurveyVoteSelection(
        'Mejor-Guachinche-Tradicional', '22222222-2222-4222-8222-222222222222');
    final request = await identity.voteRequest([selection]);
    // A previous run on this simulator may already have voted. Both paths
    // must converge to exactly one persisted vote for its native identity.
    try {
      final receipt = await repository.submitSurveyVotesV3(2, request.body,
          appCheckToken: request.appCheckToken);
      expect(receipt.accepted, [selection]);
    } on SurveyApiException catch (e) {
      expect(e.status, 409);
    }
    final second = await identity.voteRequest([selection]);
    await expectLater(
      repository.submitSurveyVotesV3(2, second.body,
          appCheckToken: second.appCheckToken),
      throwsA(isA<SurveyApiException>().having((e) => e.status, 'status', 409)),
    );
    final read = await identity.identityRequest();
    final mine = await repository.getMySurveyVotes(2, read.body,
        appCheckToken: read.appCheckToken);
    expect(mine.voted[selection.category], contains(selection.value));
    client.close();
    await tester.pumpWidget(const MaterialApp(
      home:
          Scaffold(body: Center(child: Text('Encuesta: integridad local OK'))),
    ));
    expect(find.text('Encuesta: integridad local OK'), findsOneWidget);
  });
}
