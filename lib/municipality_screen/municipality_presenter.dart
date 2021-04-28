import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/model/Municipality.dart';

class MunicipalityPresenter{
  RemoteRepository _remoteRepository;
  MunicipalityView _view;
  final storage = new FlutterSecureStorage();

  MunicipalityPresenter(this._remoteRepository, this._view);

  getAllMunicipalities() async {
    List<Municipality> municipalities = await _remoteRepository.getAllMunicipalities();

    _view.setAllMunicipalities(municipalities);
  }
  defaultSelection() async {
    String municipalityId = await storage.read(key: "municipalityId");
    _view.selectedMunicipality(municipalityId);
  }
  storeMunicipality(String municipalityName, String municipalityId) async {
    await storage.write(key: "municipalityName", value: municipalityName);
    await storage.write(key: "municipalityId", value: municipalityId);
    _view.selectedMunicipality(municipalityId);
  }
}
abstract class MunicipalityView{
  setAllMunicipalities(List<Municipality> municipalities);
  selectedMunicipality(String municipalityId);
}
