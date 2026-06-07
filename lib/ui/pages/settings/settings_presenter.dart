import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';

/// Presenter for the Settings / Profile screen (T-001).
class SettingsPresenter {
  final SettingsView _view;
  final RemoteRepository _remoteRepository;
  final UserCubit _userCubit;
  final _storage = const FlutterSecureStorage();

  SettingsPresenter(this._view, this._remoteRepository, this._userCubit);

  /// Load user info from API. Emits UserLoaded or leaves UserInitial on failure.
  Future<void> loadUser() async {
    try {
      final userId = await _storage.read(key: 'userId');
      if (userId == null || userId.isEmpty) {
        _view.onUserNotLoggedIn();
        return;
      }
      final success = await _userCubit.getUserInfo(userId);
      if (!success) {
        _view.onLoadError();
      }
    } catch (_) {
      _view.onLoadError();
    }
  }

  /// Update display name on remote + refresh cubit.
  Future<void> updateName(String newName) async {
    // TODO(backend): Wire to _remoteRepository.updateUser() when endpoint exists.
    // For now, optimistically update the cubit state with the new name.
    _view.onNameUpdated(newName);
  }

  /// Log out: clear secure storage and navigate to login.
  Future<void> logOut() async {
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    Analytics.I.reset();
    _view.onLoggedOut();
  }

  /// Delete account: call API then clear storage.
  Future<void> deleteAccount() async {
    try {
      final userId = await _storage.read(key: 'userId');
      if (userId != null && userId.isNotEmpty) {
        await _remoteRepository.deleteUser(userId);
      }
    } catch (_) {
      // Best-effort: proceed even if API fails
    }
    await _storage.deleteAll();
    Analytics.I.reset();
    _view.onLoggedOut();
  }
}

abstract class SettingsView {
  void onUserNotLoggedIn();
  void onLoadError();
  void onLoggedOut();
  void onNameUpdated(String name);
}
