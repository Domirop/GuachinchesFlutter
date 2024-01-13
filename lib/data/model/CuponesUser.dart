import 'package:guachinches/data/model/Cupones.dart';
import 'package:guachinches/data/model/User.dart';
import 'package:guachinches/globalMethods.dart';

class CuponesUser {
  String? _id;
  String? _createdAt;
  bool? _isUsed;
  String? _userId;
  String? _cuponesId;
  Cupones? _cupon;
  User? _user;


  CuponesUser(
      this._id,
      this._createdAt,
      this._isUsed,
      this._userId,
      this._cuponesId,
      );

  Cupones? get cupon => _cupon;

  set cupon(Cupones? value) {
    _cupon = value;
  }

  CuponesUser.fromJson(dynamic json) {
    _id = json["cuponesUsuario"][0]?["id"];
    _createdAt = json["cuponesUsuario"][0]?["createdAt"];
    _isUsed = json["cuponesUsuario"][0]?['isUsed'];
    _userId = json["cuponesUsuario"][0]?['userId'];
    _cuponesId = json["cuponesUsuario"][0]?['cuponesId'];
    final cuponesUsuario = json["cuponesUsuario"][0];
    final cuponesJson = cuponesUsuario?['cupones'];
    if (cuponesJson != null) {
      cuponesJson['fotoUrl'] = cuponesJson['restaurant']?['fotos'][0]?['photoUrl'];
      _cupon = Cupones.fromJson(cuponesJson);
    }
    _user = User.fromJson(json);
  }


}
