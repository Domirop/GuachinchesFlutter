/// Id : "066d25e8-3a84-4c57-8f1c-a820da6f88d5"
/// user_blocked_id : "584bc428-0f77-4406-9a81-486e83ad8526"
/// user_id : "7f88bd16-db4b-4ac6-85fb-47910b15ee74"

class BlockUser {
  BlockUser({
      String id, 
      String userBlockedId, 
      String userId,}){
    _id = id;
    _userBlockedId = userBlockedId;
    _userId = userId;
}

  BlockUser.fromJson(dynamic json) {
    _id = json['Id'];
    _userBlockedId = json['user_blocked_id'];
    _userId = json['user_id'];
  }
  String _id;
  String _userBlockedId;
  String _userId;

  String get id => _id;
  String get userBlockedId => _userBlockedId;
  String get userId => _userId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['Id'] = _id;
    map['user_blocked_id'] = _userBlockedId;
    map['user_id'] = _userId;
    return map;
  }

}