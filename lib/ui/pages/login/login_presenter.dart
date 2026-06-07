import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/push/push_notifications_service.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/ui/pages/discover/discover_screen.dart';
import 'package:guachinches/ui/pages/listas/listas_screen.dart';
import 'package:guachinches/ui/pages/map/map_search.dart';
import 'package:guachinches/ui/pages/new_home/new_home_screen.dart';
import 'package:guachinches/ui/pages/settings/settings_screen.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginPresenter{
  final RemoteRepository _remoteRepository;
  final LoginView _view;
  final storage = new FlutterSecureStorage();
  final UserCubit _userCubit;

  LoginPresenter(this._remoteRepository, this._view, this._userCubit);

  login(String email, String password) async{
    try{
    var userId = await _remoteRepository.loginUser(email,password);
    if (userId == null) {
      _view.loginError();
      return;
    }
    List<Widget> screens = [
      const NewHomeScreen(),
      const ListasScreen(),
      MapSearch(),
      const DiscoverScreen(),
      const SettingsScreen(),
    ];
    await storage.write(key: "userId", value: userId["id"]);
    await storage.write(key: "accessToken", value: userId["accessToken"]);
    await storage.write(key: "refreshToken", value: userId["refreshToken"]);
    _userCubit.getUserInfo(userId["id"]);
    Analytics.I.identify(userId["id"] as String);
    bool deletionPending = false;
    try {
      deletionPending = (userId['deletionPending'] as bool?) == true;
    } catch (_) {}
    await PushNotificationsService.instance.init();
    _view.loginSuccess(screens, deletionPending: deletionPending, userId: userId["id"] as String);
  }catch(e){
      _view.loginError();
    }
  }

  // Google Cloud OAuth iOS client (no Firebase). Mantener sincronizado con
  // `GIDClientID` en ios/Runner/Info.plist y con el `aud` que valida el backend.
  static const _googleIosClientId =
      '138481024291-hmgnpru6pf1v5mlk7cdlh39ac2srgthc.apps.googleusercontent.com';

  loginWithGoogle() async {
    debugPrint('[GoogleLogin] start, iosClientId='
        '${Platform.isIOS ? _googleIosClientId : "<android>"}');
    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? _googleIosClientId : null,
      );
      debugPrint('[GoogleLogin] GoogleSignIn created, calling signIn()…');

      final account = await googleSignIn.signIn();
      if (account == null) {
        debugPrint('[GoogleLogin] user cancelled (account=null)');
        return;
      }
      debugPrint('[GoogleLogin] account=${account.email} id=${account.id}');

      debugPrint('[GoogleLogin] fetching authentication…');
      final auth = await account.authentication;
      final idToken = auth.idToken;
      debugPrint('[GoogleLogin] idToken? ${idToken != null} '
          'len=${idToken?.length ?? 0}');
      if (idToken == null) throw Exception('No id token from Google');

      debugPrint('[GoogleLogin] POST /auth/google …');
      final response = await _remoteRepository.loginWithGoogle(idToken);
      debugPrint('[GoogleLogin] backend response keys=${response.keys.toList()}');

      final id = response['id'] as String;
      await storage.write(key: 'userId', value: id);
      _userCubit.getUserInfo(id);
      Analytics.I.identify(id);
      List<Widget> screens = [
        const NewHomeScreen(),
        const ListasScreen(),
        MapSearch(),
        const DiscoverScreen(),
        const SettingsScreen(),
      ];
      bool deletionPending = false;
      try {
        deletionPending = (response['deletionPending'] as bool?) == true;
      } catch (_) {}
      debugPrint('[GoogleLogin] success, navigating');
      await PushNotificationsService.instance.init();
      _view.loginSuccess(screens, deletionPending: deletionPending, userId: id);
    } on PlatformException catch (e, st) {
      debugPrint('[GoogleLogin] PlatformException code=${e.code} '
          'message=${e.message} details=${e.details}');
      debugPrint('$st');
      _view.loginError();
    } catch (e, st) {
      debugPrint('[GoogleLogin] ERROR type=${e.runtimeType} msg=$e');
      debugPrint('$st');
      _view.loginError();
    }
  }

  loginWithApple() async {
    if (!Platform.isIOS) return;
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) throw Exception('No identity token from Apple');
      final response = await _remoteRepository.loginWithApple(
        idToken,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
      final id = response['id'] as String;
      await storage.write(key: 'userId', value: id);
      _userCubit.getUserInfo(id);
      Analytics.I.identify(id);
      List<Widget> screens = [
        const NewHomeScreen(),
        const ListasScreen(),
        MapSearch(),
        const DiscoverScreen(),
        const SettingsScreen(),
      ];
      bool deletionPending = false;
      try {
        deletionPending = (response['deletionPending'] as bool?) == true;
      } catch (_) {}
      await PushNotificationsService.instance.init();
      _view.loginSuccess(screens, deletionPending: deletionPending, userId: id);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      _view.loginError();
    } catch (e) {
      _view.loginError();
    }
  }
}

abstract class LoginView{
  loginSuccess(List<Widget> screens, {bool deletionPending, String userId});
  loginError();
}

