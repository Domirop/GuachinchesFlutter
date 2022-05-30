import 'package:bloc/bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/user_info.dart';

class UserCubit extends Cubit<UserState> {
  final RemoteRepository _remoteRepository;
  UserInfo user;

  UserCubit(this._remoteRepository) : super(UserInitial());

  Future<bool> getUserInfo(String userId) async {
    try{
      UserInfo userInfo = await _remoteRepository.getUserInfo(userId).timeout(const Duration(seconds: 5));
      emit(UserLoaded(userInfo));
      return true;
    }catch (e){
      return false;
    }
  }
  Future<bool> updateUserReview(String userId, String reviewId, String title, String rating, String review) async {
    await _remoteRepository.updateReview(userId,reviewId, title, rating, review);
    UserInfo userInfo = await _remoteRepository.getUserInfo(userId);
    emit(UserLoaded(userInfo));
    return true;
  }
}
