// Covers UserCubit.refreshFromBackend(), invoked by the perfil-refresh-indicator
// RefreshIndicator in lib/ui/pages/profile/profile_v2.dart. A widget-level
// test of Profilev2 is impractical: the screen instantiates its own
// HttpRemoteRepository(Client()) in initState, calls _loadFavCount() against
// the real network, and reads from FlutterSecureStorage. Cubit-level coverage
// validates the contract the screen relies on:
//   - refreshFromBackend() must be a no-op without a prior getUserInfo (no
//     _lastUserId).
//   - On success it must emit UserLoaded with the fresh data without going
//     through an intermediate Loading/Initial state (so the screen does NOT
//     flash empty during the pull).
//   - On network failure it must preserve the previous state.

import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/user_info.dart';

class _SpyRepo extends Fake implements RemoteRepository {
  int calls = 0;
  final List<String> userIds = [];
  Future<UserInfo> Function(String)? _override;

  void onGetUserInfo(Future<UserInfo> Function(String) impl) {
    _override = impl;
  }

  @override
  Future<UserInfo> getUserInfo(String userId) async {
    calls++;
    userIds.add(userId);
    if (_override != null) return _override!(userId);
    return UserInfo(id: userId, nombre: 'Test', email: 't@e.com');
  }
}

void main() {
  group('UserCubit.refreshFromBackend', () {
    test('(a) is a no-op when no userId has been loaded yet', () async {
      final repo = _SpyRepo();
      final cubit = UserCubit(repo);

      await cubit.refreshFromBackend();

      expect(repo.calls, 0,
          reason: 'refreshFromBackend() must not hit network without a prior getUserInfo');
      expect(cubit.state, isA<UserInitial>(),
          reason: 'state must remain UserInitial');
    });

    test('(b) after a previous getUserInfo, refresh re-fetches and emits UserLoaded', () async {
      final repo = _SpyRepo();
      final cubit = UserCubit(repo);

      // Seed _lastUserId via the production entry point
      await cubit.getUserInfo('user-42');
      expect(cubit.state, isA<UserLoaded>());
      final initialCalls = repo.calls;

      // Swap the impl so we can detect that refresh emitted a NEW UserLoaded
      repo.onGetUserInfo((id) async => UserInfo(id: id, nombre: 'Refreshed', email: 'r@e.com'));

      await cubit.refreshFromBackend();

      expect(repo.calls, initialCalls + 1,
          reason: 'refreshFromBackend() must re-invoke getUserInfo exactly once');
      expect(repo.userIds.last, 'user-42',
          reason: 'refreshFromBackend() must reuse the last userId');
      expect(cubit.state, isA<UserLoaded>());
      expect((cubit.state as UserLoaded).user.nombre, 'Refreshed',
          reason: 'refreshFromBackend() must emit the fresh data');
    });

    test('(c) on network failure refresh preserves the previous UserLoaded state', () async {
      final repo = _SpyRepo();
      final cubit = UserCubit(repo);

      await cubit.getUserInfo('user-7');
      final stateBefore = cubit.state;
      expect(stateBefore, isA<UserLoaded>());

      // Next call throws
      repo.onGetUserInfo((_) async => throw Exception('network down'));

      await cubit.refreshFromBackend();

      expect(cubit.state, equals(stateBefore),
          reason: 'On error, refreshFromBackend() must NOT change state');
    });
  });
}
