import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/visits/user_visits_cubit.dart';
import 'package:guachinches/data/cubit/visits/user_visits_state.dart';
import 'package:guachinches/data/model/user_visit.dart';

class _FakeRepo extends Fake implements RemoteRepository {
  final Future<List<UserVisit>> Function(String) _impl;

  _FakeRepo(this._impl);

  @override
  Future<List<UserVisit>> getUserVisits(String userId) => _impl(userId);
}

UserVisit _visit(String id) => UserVisit(
      id: id,
      restaurantId: 'r-$id',
      restaurantName: 'Restaurant $id',
      visitedAt: DateTime(2025, 1, 1),
    );

void main() {
  group('UserVisitsCubit', () {
    test('(a) load with non-empty list emits [Loading, Loaded]', () async {
      final cubit = UserVisitsCubit(
        _FakeRepo((_) async => [_visit('1'), _visit('2')]),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const UserVisitsLoading(),
          isA<UserVisitsLoaded>()
              .having((s) => s.visits.length, 'visits.length', 2),
        ]),
      );
      cubit.load('user-1');
      await expectation;
    });

    test('(b) load with empty list emits [Loading, Empty]', () async {
      final cubit = UserVisitsCubit(
        _FakeRepo((_) async => []),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const UserVisitsLoading(),
          const UserVisitsEmpty(),
        ]),
      );
      cubit.load('user-1');
      await expectation;
    });

    test('(c) load with repo exception emits [Loading, Error]', () async {
      final cubit = UserVisitsCubit(
        _FakeRepo((_) async => throw Exception('network error')),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const UserVisitsLoading(),
          isA<UserVisitsError>(),
        ]),
      );
      cubit.load('user-1');
      await expectation;
    });

    test('(d) refresh re-emits Loading → Loaded sequence', () async {
      final cubit = UserVisitsCubit(
        _FakeRepo((_) async => [_visit('x')]),
      );

      // prime with a load first
      await cubit.load('user-1');

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const UserVisitsLoading(),
          isA<UserVisitsLoaded>()
              .having((s) => s.visits.first.id, 'visit id', 'x'),
        ]),
      );
      cubit.refresh('user-1');
      await expectation;
    });
  });
}
