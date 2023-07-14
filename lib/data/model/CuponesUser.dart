import 'package:guachinches/data/model/Cupones.dart';
import 'package:guachinches/data/model/User.dart';
import 'package:guachinches/globalMethods.dart';

class CuponesUser {
  String _id;
  String _craetedAt;
  bool _isUsed;
  String _userId;
  String _cuponesId;
  Cupones _cupon;
  User _user;

  CuponesUser(
      this._id, this._craetedAt, this._isUsed, this._userId, this._cuponesId);

  Cupones get cupon => _cupon;

  set cupon(Cupones value) {
    _cupon = value;
  }

  CuponesUser.fromJson(dynamic json) {
    print('json');
    print(json["cuponesUsuario"][0]);
      _id = json["cuponesUsuario"][0]["id"];
      _craetedAt = json["cuponesUsuario"][0]["createdAt"];
      _isUsed = json["cuponesUsuario"][0]['isUsed'];
      _userId = json["cuponesUsuario"][0]['userId'];
      _cuponesId = json["cuponesUsuario"][0]['cuponesId'];
      json["cuponesUsuario"][0]['cupones']['fotoUrl']= json["cuponesUsuario"][0]['cupones']['restaurant']['fotos'][0]['photoUrl'];
      _cupon = Cupones.fromJson(json["cuponesUsuario"][0]['cupones']);
      _user = User.fromJson(json);
  }

  String get cuponesId => _cuponesId;

  set cuponesId(String value) {
    _cuponesId = value;
  }

  String get userId => _userId;

  set userId(String value) {
    _userId = value;
  }

  bool get isUsed => _isUsed;

  set isUsed(bool value) {
    _isUsed = value;
  }

  String get craetedAt => _craetedAt;

  set craetedAt(String value) {
    _craetedAt = value;
  }

  String get id => _id;

  set id(String value) {
    _id = value;
  }

  User get user => _user;

  set user(User value) {
    _user = value;
  }
}
