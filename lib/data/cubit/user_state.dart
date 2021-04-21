
import 'package:flutter/foundation.dart';
import 'package:guachinches/model/User.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:guachinches/model/user_info.dart';

@immutable
abstract class UserState {
  const UserState();

}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoaded extends UserState {
  final UserInfo user;
  const UserLoaded(this.user);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is UserLoaded && o.user == user;
  }

  @override
  int get hashCode => user.hashCode;
}
