import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/local/sql_lite_local_repository.dart';
import 'package:uuid/uuid.dart';

class SurveyDetailsPresenter {
  RemoteRepository _remoteRepository;
  final storage = new FlutterSecureStorage();
  SqlLiteLocalRepository sqlLiteLocalRepository = SqlLiteLocalRepository();
  SurveyDetailsView _view;

  SurveyDetailsPresenter(this._remoteRepository, this._view);

  getUserSurveyId() async {
    String? surveyUserId = await storage.read(key: "surveyUserId");

    if (surveyUserId == null || surveyUserId == '69a54c41-5ae3-5445-bea3-4e16ec8092fa') {
      String? userId = await storage.read(key: "userId");


      // if (userId != null) {
      //   await storage.write(key: "surveyUserId", value: userId);
      // } else {
      //   try {
      //     final deviceId = await PlatformDeviceId.getDeviceId;
      //     if (deviceId != null) {
      //       final generatedUuid = const Uuid().v5(Uuid.NAMESPACE_URL, deviceId);
      //       await storage.write(key: "surveyUserId", value: generatedUuid);
      //     } else {
      //       final fallbackUuid = const Uuid().v4();
      //       await storage.write(key: "surveyUserId", value: fallbackUuid);
      //     }
      //   } catch (e) {
      //     // En caso de error, se cae a UUID v4 también
      //     final fallbackUuid = const Uuid().v4();
      //     await storage.write(key: "surveyUserId", value: fallbackUuid);
      //   }
      // }
    }
    _view.setUserSurveyId(surveyUserId!);
  }
}

abstract class SurveyDetailsView {
  setUserSurveyId(String surveyUserId);
}
