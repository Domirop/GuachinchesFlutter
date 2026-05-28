import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/visits/user_visits_cubit.dart';
import 'package:guachinches/data/cubit/visits/user_visits_state.dart';
import 'package:guachinches/data/model/user_visit.dart';
import 'package:guachinches/ui/components/cards/visit_card.dart';
import 'package:guachinches/ui/pages/visitas/visitas_screen.dart';

class _FakeRepo extends Fake implements RemoteRepository {
  @override
  Future<List<UserVisit>> getUserVisits(String userId) async => [];
}

/// Extends UserVisitsCubit so it is assignable to BlocProvider<UserVisitsCubit>.
/// Starts in [initialState]; load/refresh are no-ops so no repo call is made.
class _MockUserVisitsCubit extends UserVisitsCubit {
  _MockUserVisitsCubit(UserVisitsState initialState) : super(_FakeRepo()) {
    emit(initialState);
  }

  @override
  Future<void> load(String userId) async {}

  @override
  Future<void> refresh(String userId) async {}
}

Widget _wrap(UserVisitsState initialState) {
  final cubit = _MockUserVisitsCubit(initialState);
  final repo = _FakeRepo();
  return MultiBlocProvider(
    providers: [
      BlocProvider<UserVisitsCubit>.value(value: cubit),
      BlocProvider<UserCubit>(create: (_) => UserCubit(repo)),
      BlocProvider<MenuCubit>(create: (_) => MenuCubit()),
    ],
    child: MaterialApp(
      theme: appDarkTheme,
      home: const VisitasScreen(),
    ),
  );
}

UserVisit _visit(String id) => UserVisit(
      id: id,
      restaurantId: 'r-$id',
      restaurantName: 'Restaurante $id',
      visitedAt: DateTime(2024, 6, 1),
    );

void main() {
  group('VisitasScreen', () {
    testWidgets(
        '(a) UserVisitsEmpty shows empty text and visitas-empty-cta',
        (tester) async {
      await tester.pumpWidget(_wrap(const UserVisitsEmpty()));
      await tester.pump();

      expect(
        find.text('Aún no has visitado ningún restaurante'),
        findsOneWidget,
      );

      final cta = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'visitas-empty-cta',
      );
      expect(cta, findsOneWidget);
    });

    testWidgets(
        '(b) UserVisitsLoaded with N items shows N VisitCard + visitas-list',
        (tester) async {
      const n = 3;
      final visits = List.generate(n, (i) => _visit('$i'));

      await tester.pumpWidget(_wrap(UserVisitsLoaded(visits)));
      await tester.pump();

      expect(find.byType(VisitCard), findsNWidgets(n));

      final list = find.byWidgetPredicate(
        (w) =>
            w is Semantics && w.properties.identifier == 'visitas-list',
      );
      expect(list, findsOneWidget);
    });
  });
}
