import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/model/Municipality.dart';
import 'package:guachinches/splash_screen/splash_screen.dart';

class MunicipalityPresenter{
  RemoteRepository _remoteRepository;
  MunicipalityView _view;
  final storage = new FlutterSecureStorage();

  MunicipalityPresenter(this._remoteRepository, this._view);

  getAllMunicipalities() async {
    List<Municipality> municipalities = await _remoteRepository.getAllMunicipalities();
    _view.setAllMunicipalities(municipalities);
  }
  storeMunicipality(String municipalityName, String municipalityId, String municipalityIdArea, String municipalityNameArea, context) async {
    if(municipalityId == null){
      if(municipalityIdArea == "Todos"){
        await storage.write(key: "municipalityIdArea", value: "");
        await storage.write(key: "municipalityNameArea", value: "");
        await storage.write(key: "municipalityName", value: "");
        await storage.write(key: "municipalityId", value: "");
        await storage.write(key: "useMunicipality", value: "Todos");
      }else{
        await storage.write(key: "municipalityIdArea", value: municipalityIdArea);
        await storage.write(key: "municipalityNameArea", value: municipalityNameArea);
        await storage.write(key: "municipalityName", value: "");
        await storage.write(key: "municipalityId", value: "");
        await storage.write(key: "useMunicipality", value: "false");
      }
    }else{
      await storage.write(key: "municipalityName", value: municipalityName);
      await storage.write(key: "municipalityId", value: municipalityId);
      await storage.write(key: "municipalityIdArea", value: "");
      await storage.write(key: "municipalityNameArea", value: "");
      await storage.write(key: "useMunicipality", value: "true");
    }
    _view.setMunicipality();
  }
}
abstract class MunicipalityView{
  setAllMunicipalities(List<Municipality> municipalities);
  setMunicipality();
}
