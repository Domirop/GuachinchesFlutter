import 'package:guachinches/data/model/user_visit.dart';

abstract class UserVisitsState {
  const UserVisitsState();
}

class UserVisitsInitial extends UserVisitsState {
  const UserVisitsInitial();

  @override
  bool operator ==(Object other) => other is UserVisitsInitial;

  @override
  int get hashCode => runtimeType.hashCode;
}

class UserVisitsLoading extends UserVisitsState {
  const UserVisitsLoading();

  @override
  bool operator ==(Object other) => other is UserVisitsLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

class UserVisitsLoaded extends UserVisitsState {
  final List<UserVisit> visits;

  const UserVisitsLoaded(this.visits);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserVisitsLoaded && other.visits == visits;
  }

  @override
  int get hashCode => visits.hashCode;
}

class UserVisitsEmpty extends UserVisitsState {
  const UserVisitsEmpty();

  @override
  bool operator ==(Object other) => other is UserVisitsEmpty;

  @override
  int get hashCode => runtimeType.hashCode;
}

class UserVisitsError extends UserVisitsState {
  final String message;

  const UserVisitsError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserVisitsError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
