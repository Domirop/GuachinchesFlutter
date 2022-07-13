import 'package:guachinches/data/RemoteRepository.dart';

class RegisterPresenter{
  final RemoteRepository _remoteRepository;
  final RegisterView _view;

  RegisterPresenter(this._remoteRepository, this._view);

  register(Map data) async{
    String correctInsert = await _remoteRepository.registerUser(data);
    if(correctInsert == 'true'){
      _view.correctInsert();
    }else{
      _view.errorInsert(correctInsert);
    }
  }
}

abstract class RegisterView{
  errorInsert(String error);
  correctInsert();
}
