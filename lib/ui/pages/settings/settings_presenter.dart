import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/ui/pages/settings/session_profile.dart';
import 'package:guachinches/services/app_storage.dart';

/// Presenter de la pestaña Perfil (tablero TabPerfil).
class SettingsPresenter {
  final SettingsView _view;
  final UserCubit _userCubit;
  final FlutterSecureStorage _storage;
  final SessionProfileStore _session;

  SettingsPresenter(
    this._view,
    this._userCubit, {
    FlutterSecureStorage storage = AppStorage.instance,
    SessionProfileStore session = const SessionProfileStore(),
  })  : _storage = storage,
        _session = session;

  /// Carga el perfil. Sin `userId` → invitado; con él y fallo de red →
  /// error parcial (la sesión sigue abierta).
  Future<void> loadUser() async {
    try {
      final userId = await _storage.read(key: 'userId');
      if (userId == null || userId.isEmpty) {
        _view.onUserNotLoggedIn();
        return;
      }
      final success = await _userCubit.getUserInfo(userId);
      if (!success) _view.onLoadError();
    } catch (e) {
      AppLogger.warn('perfil', 'no se pudo cargar el perfil: $e');
      _view.onLoadError();
    }
  }

  /// Cierra sesión: borra la sesión del móvil (los guardados se quedan) y
  /// vuelve al Perfil sin sesión.
  Future<void> logOut() async {
    await _storage.delete(key: 'userId');
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _session.clear();
    Analytics.I.reset();
    _userCubit.reset();
    _view.onLoggedOut();
  }
}

abstract class SettingsView {
  void onUserNotLoggedIn();
  void onLoadError();
  void onLoggedOut();
}
