import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/survey_in_app_choice.dart';
import 'package:guachinches/data/model/survey_v3.dart';
import 'package:guachinches/services/survey_integrity/device_identity_service.dart';

const kTrad = 'Mejor-Guachinche-Tradicional';
const kMod = 'Mejor-Guachinche-Moderno';

/// Valores «sensibles» de las fakes: ninguno puede aparecer en un log.
const kTokenPrefix = 'APPCHECK-SENSITIVE-';

SurveyEdition edition({
  SurveyEditionStatus status = SurveyEditionStatus.open,
  Map<String, String> minAppVersion = const {'ios': '4.7.0', 'android': '4.7.0'},
  String voteScope = 'business',
}) =>
    SurveyEdition(
      editionId: 2,
      label: 'Premios 2027',
      status: status,
      minAppVersion: minAppVersion,
      voteScope: voteScope,
      categories: const [kTrad, kMod],
    );

/// Keychain en memoria que recuerda con qué opciones se escribió cada clave.
/// Sobrevive a «reinicios» (instancias nuevas de [KeychainLocalIdSource]) igual
/// que el Keychain real.
class MemorySecureStorage implements FlutterSecureStorage {
  final Map<String, String> items = {};
  final Map<String, IOSOptions?> writeOptions = {};
  PlatformException? readError;
  int reads = 0, writes = 0;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    reads++;
    if (readError != null) throw readError!;
    return items['${iOptions?.toMap()['accountName']}/$key'];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    writes++;
    items['${iOptions?.toMap()['accountName']}/$key'] = value!;
    writeOptions[key] = iOptions;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalIdSource implements LocalIdSource {
  int calls = 0;
  final String hash;
  FakeLocalIdSource([String? hash]) : hash = hash ?? 'a' * 64;

  @override
  Future<SurveyLocalId> localId() async {
    calls++;
    return SurveyLocalId(hash);
  }
}

class FakeAppCheck implements AppCheckTokenSource {
  int activations = 0;
  final tokens = <String>[];
  final standardTokens = <String>[];
  SurveyIntegrityException? activateError;
  final tokenErrors = <SurveyIntegrityException>[];

  @override
  Future<void> activate() async {
    activations++;
    if (activateError != null) throw activateError!;
  }

  @override
  Future<String> limitedUseToken() async {
    if (tokenErrors.isNotEmpty) throw tokenErrors.removeAt(0);
    final t = '$kTokenPrefix${tokens.length + 1}';
    tokens.add(t);
    return t;
  }

  @override
  Future<String> standardToken() async {
    if (tokenErrors.isNotEmpty) throw tokenErrors.removeAt(0);
    final t = '${kTokenPrefix}STD-${standardTokens.length + 1}';
    standardTokens.add(t);
    return t;
  }
}

DeviceIdentityService identity({
  String platform = 'ios',
  LocalIdSource? localIds,
  AppCheckTokenSource? appCheck,
}) =>
    DeviceIdentityService(
      localIds: localIds ?? FakeLocalIdSource(),
      appCheck: appCheck ?? FakeAppCheck(),
      platform: platform,
    );

/// Respuesta programable: un valor o una excepción.
typedef Step<T> = T Function();

class SentRequest {
  final Map<String, Object?> body;
  final String token;
  SentRequest(this.body, this.token);
}

class FakeSurveyRepo extends Fake implements RemoteRepository {
  SurveyEdition currentEdition = edition();
  final choices = <String, List<SurveyInAppChoice>>{
    kTrad: [
      SurveyInAppChoice(value: 'r-t1', text: 'Tradicional 1'),
      SurveyInAppChoice(value: 'r-t2', text: 'Tradicional 2'),
      SurveyInAppChoice(value: 'r-both', text: 'En las dos'),
    ],
    kMod: [
      SurveyInAppChoice(value: 'r-m1', text: 'Moderno 1'),
      SurveyInAppChoice(value: 'r-both', text: 'En las dos'),
    ],
  };

  SurveyMyVotes mine = const SurveyMyVotes();
  final mineSteps = <Step<SurveyMyVotes>>[];
  final voteSteps = <Step<SurveyVoteReceipt>>[];
  final editionSteps = <Step<SurveyEdition>>[];

  final mineReads = <SentRequest>[];
  final votes = <SentRequest>[];
  int editionCalls = 0;

  @override
  Future<SurveyEdition> getCurrentSurveyEdition() async {
    editionCalls++;
    if (editionSteps.isNotEmpty) return editionSteps.removeAt(0)();
    return currentEdition;
  }

  @override
  Future<List<SurveyInAppChoice>> getSurveyEditionChoices(int editionId, String categoryName) async =>
      List.of(choices[categoryName] ?? const []);

  @override
  Future<SurveyMyVotes> getMySurveyVotes(int editionId, Map<String, Object?> body,
      {required String appCheckToken}) async {
    mineReads.add(SentRequest(body, appCheckToken));
    if (mineSteps.isNotEmpty) return mineSteps.removeAt(0)();
    return mine;
  }

  @override
  Future<SurveyVoteReceipt> submitSurveyVotesV3(int editionId, Map<String, Object?> body,
      {required String appCheckToken}) async {
    votes.add(SentRequest(body, appCheckToken));
    if (voteSteps.isNotEmpty) return voteSteps.removeAt(0)();
    final sent = [
      for (final v in body['votes'] as List)
        SurveyVoteSelection((v as Map)['category'] as String, v['value'] as String)
    ];
    return SurveyVoteReceipt(accepted: sent, voted: const {});
  }
}

Never apiError(int status, String code, {Map<String, dynamic> details = const {}, Duration? retryAfter}) =>
    throw SurveyApiException(status, code, details: details, retryAfter: retryAfter);
