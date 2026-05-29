import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/user_info.dart';

class UserCubit extends Cubit<UserState> {
  final RemoteRepository _remoteRepository;
  late UserInfo user;
  String? _lastUserId;

  UserCubit(this._remoteRepository) : super(UserInitial());

  Future<bool> getUserInfo(String userId) async {
    _lastUserId = userId;
    debugPrint('[UserCubit] getUserInfo userId=$userId');
    try {
      UserInfo userInfo = await _remoteRepository
          .getUserInfo(userId)
          .timeout(const Duration(seconds: 15));
      debugPrint('[UserCubit] getUserInfo OK email=${userInfo.email}');
      emit(UserLoaded(userInfo));
      return true;
    } catch (e, st) {
      debugPrint('[UserCubit] getUserInfo FAILED type=${e.runtimeType} msg=$e');
      debugPrint('$st');
      return false;
    }
  }

  /// Re-fetches user data without transitioning to UserInitial.
  /// On error the previous state is preserved.
  Future<void> refreshFromBackend() async {
    final userId = _lastUserId;
    if (userId == null || userId.isEmpty) return;
    try {
      final userInfo = await _remoteRepository
          .getUserInfo(userId)
          .timeout(const Duration(seconds: 15));
      emit(UserLoaded(userInfo));
    } catch (_) {
      // Keep previous state on error — no intermediate loading emitted.
    }
  }
  Future<bool> updateUserReview(String userId, String reviewId, String title, String rating, String review) async {
    await _remoteRepository.updateReview(userId,reviewId, title, rating, review);
    UserInfo userInfo = await _remoteRepository.getUserInfo(userId);
    emit(UserLoaded(userInfo));
    return true;
  }
}
