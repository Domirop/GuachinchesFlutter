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

    if (surveyUserId == null) {
      // No existe surveyUserId, revisamos userId
      String? userId = await storage.read(key: "userId");

      if (userId != null) {
        await storage.write(key: "surveyUserId", value: userId);
      } else {
        // No hay userId, generamos un UUID4
        var uuid = const Uuid().v4();
        await storage.write(key: "surveyUserId", value: uuid);
      }
    }
    _view.setUserSurveyId(surveyUserId!);
  }
}

abstract class SurveyDetailsView {
  setUserSurveyId(String surveyUserId);
}
