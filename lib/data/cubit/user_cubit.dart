import 'package:bloc/bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user_state.dart';
import 'package:guachinches/model/Review.dart';
import 'package:guachinches/model/User.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:guachinches/data/cubit/restaurant_state.dart';
import 'package:guachinches/model/user_info.dart';

class UserCubit extends Cubit<UserState> {
  final RemoteRepository _remoteRepository;
  UserInfo user;

  UserCubit(this._remoteRepository) : super(UserInitial());

  Future<void> getUserInfo(String userId) async {
  UserInfo userInfo = await _remoteRepository.getUserInfo(userId);
  emit(UserLoaded(userInfo));

  }
  Future<bool> updateUserReview(String userId, String reviewId, String title, String rating, String review) async {
    await _remoteRepository.updateReview(userId,reviewId, title, rating, review);
    UserInfo userInfo = await _remoteRepository.getUserInfo(userId);
    emit(UserLoaded(userInfo));
    return true;
  }
}