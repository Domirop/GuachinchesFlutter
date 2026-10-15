import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/core/push/push_notifications_service.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/ui/pages/login/login_logic.dart';
import 'package:guachinches/ui/pages/profile/account_deletion_store.dart';
import 'package:guachinches/ui/pages/settings/perfil_logic.dart';
import 'package:guachinches/ui/pages/settings/session_profile.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:guachinches/services/app_storage.dart';

/// Lo que el acceso necesita del mundo exterior. [LoginPresenter] es la
/// implementación real; las pruebas usan una falsa.
abstract class LoginAuth {
  /// Apple solo existe en iOS.
  bool get appleAvailable;

  /// Entra con [method]; email y contraseña solo para [LoginMethod.email].
  Future<LoginOutcome> signIn(LoginMethod method,
      {String email = '', String password = ''});

  /// Cancela la eliminación programada. `false` si el backend falla.
  Future<bool> keepAccount(String userId);

  /// Cierra la sesión recién abierta (eliminación pendiente → «Cerrar sesión»).
  Future<void> signOut();
}

/// Entrar con email, Google o Apple y dejar la sesión guardada como
/// siempre: `userId` (+ tokens del login con email) en el almacenamiento
/// seguro, email/proveedor en [SessionProfileStore], perfil en [UserCubit],
/// analítica y notificaciones. No navega: quien llama decide.
class LoginPresenter implements LoginAuth {
  final RemoteRepository _remoteRepository;
  final UserCubit _userCubit;
  final FlutterSecureStorage _storage;
  final SessionProfileStore _session;
  final AccountDeletionStore _deletion;

  LoginPresenter(
    this._remoteRepository,
    this._userCubit, {
    FlutterSecureStorage storage = AppStorage.instance,
    SessionProfileStore session = const SessionProfileStore(),
    AccountDeletionStore deletion = const AccountDeletionStore(),
  })  : _storage = storage,
        _session = session,
        _deletion = deletion;

  // Google Cloud OAuth iOS client (no Firebase). Mantener sincronizado con
  // `GIDClientID` en ios/Runner/Info.plist y con el `aud` que valida el backend.
  static const _googleIosClientId =
      '138481024291-hmgnpru6pf1v5mlk7cdlh39ac2srgthc.apps.googleusercontent.com';

  @override
  bool get appleAvailable => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<LoginOutcome> signIn(LoginMethod method,
      {String email = '', String password = ''}) {
    switch (method) {
      case LoginMethod.email:
        return _loginWithEmail(email.trim(), password);
      case LoginMethod.google:
        return _loginWithGoogle();
      case LoginMethod.apple:
        return _loginWithApple();
    }
  }

  Future<LoginOutcome> _loginWithEmail(String email, String password) async {
    try {
      final result = await _remoteRepository.loginUser(email, password);
      if (result is! Map || result['id'] is! String) {
        return const LoginOutcome.failed(LoginFailure.credentials);
      }
      final response = Map<String, dynamic>.from(result);
      final id = response['id'] as String;
      await _storage.write(key: 'userId', value: id);
      await _storage.write(
          key: 'accessToken', value: response['accessToken'] as String?);
      await _storage.write(
          key: 'refreshToken', value: response['refreshToken'] as String?);
      // Perfil: el backend ya no devuelve el email (042); se guarda el tecleado.
      await _session.saveLogin(provider: PerfilProvider.email, email: email);
      return LoginOutcome.success(
          await _opened(id, LoginMethod.email, email, response));
    } catch (e) {
      AppLogger.warn('login', 'email: ${e.runtimeType}');
      return LoginOutcome.failed(loginClassifyEmailError(e));
    }
  }

  Future<LoginOutcome> _loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? _googleIosClientId : null,
      );
      final account = await googleSignIn.signIn();
      if (account == null) return LoginOutcome.cancelled;
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw StateError('Google sin idToken');
      final response = await _remoteRepository.loginWithGoogle(idToken);
      final id = response['id'] as String;
      final email = (response['email'] as String?) ?? account.email;
      await _storage.write(key: 'userId', value: id);
      // Perfil: email y proveedor de la sesión (el backend ya no los da, 042).
      await _session.saveLogin(provider: PerfilProvider.google, email: email);
      return LoginOutcome.success(
          await _opened(id, LoginMethod.google, email, response));
    } on PlatformException catch (e) {
      AppLogger.warn('login', 'google: ${e.code} ${e.message}');
      return LoginOutcome.failed(
          loginClassifyProviderError(e, platformCode: e.code));
    } catch (e) {
      AppLogger.warn('login', 'google: ${e.runtimeType} $e');
      return LoginOutcome.failed(loginClassifyProviderError(e));
    }
  }

  Future<LoginOutcome> _loginWithApple() async {
    if (!Platform.isIOS) return LoginOutcome.cancelled;
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) throw StateError('Apple sin identityToken');
      final response = await _remoteRepository.loginWithApple(
        idToken,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
      final id = response['id'] as String;
      final email = (response['email'] as String?) ?? credential.email;
      await _storage.write(key: 'userId', value: id);
      await _session.saveLogin(provider: PerfilProvider.apple, email: email);
      return LoginOutcome.success(
          await _opened(id, LoginMethod.apple, email, response));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return LoginOutcome.cancelled;
      }
      AppLogger.warn('login', 'apple: ${e.code} ${e.message}');
      return const LoginOutcome.failed(LoginFailure.unknown);
    } on PlatformException catch (e) {
      AppLogger.warn('login', 'apple: ${e.code} ${e.message}');
      return LoginOutcome.failed(
          loginClassifyProviderError(e, platformCode: e.code));
    } catch (e) {
      AppLogger.warn('login', 'apple: ${e.runtimeType} $e');
      return LoginOutcome.failed(loginClassifyProviderError(e));
    }
  }

  /// Común a los tres métodos tras guardar la sesión.
  Future<LoginSession> _opened(String id, LoginMethod method, String? email,
      Map<String, dynamic> response) async {
    final now = DateTime.now();
    final pending = loginDeletionPending(response, now);
    var deletionAt = loginDeletionAt(response);
    if (deletionAt != null && deletionAt.isAfter(now)) {
      await _deletion.save(id, deletionAt);
    } else if (pending) {
      // Sin fecha en la respuesta: la que se guardó al pedirla en este móvil.
      deletionAt = await _deletion.read(id);
    }
    // Se pide en segundo plano: el Perfil escucha al cubit.
    _userCubit.getUserInfo(id);
    Analytics.I.identify(id);
    try {
      await PushNotificationsService.instance.init();
    } catch (e) {
      // Las notificaciones no bloquean la entrada.
      AppLogger.warn('login', 'push init: $e');
    }
    return LoginSession(
      userId: id,
      method: method,
      email: email,
      deletionPending: pending,
      deletionAt: deletionAt,
    );
  }

  @override
  Future<bool> keepAccount(String userId) async {
    try {
      await _remoteRepository.cancelAccountDeletion(userId);
      await _deletion.clear(userId);
      return true;
    } catch (e) {
      AppLogger.warn('login', 'no se pudo cancelar la eliminación: $e');
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _storage.delete(key: 'userId');
      await _storage.delete(key: 'accessToken');
      await _storage.delete(key: 'refreshToken');
    } catch (e) {
      AppLogger.warn('login', 'no se pudo borrar la sesión: $e');
    }
    await _session.clear();
    Analytics.I.reset();
    _userCubit.reset();
  }
}
