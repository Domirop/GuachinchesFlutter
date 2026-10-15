import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/ui/pages/valoraciones/valoraciones.dart';

import '../settings/perfil_test_harness.dart';

UserInfo _user(List<Valoraciones> reviews) =>
    UserInfo(id: 'u1', nombre: 'Carmen', valoraciones: reviews);

Future<FakePerfilRepo> _pump(
  WidgetTester tester, {
  UserInfo? user,
  bool failUser = false,
  UserState seed = const UserInitial(),
}) async {
  useTallSurface(tester);
  FlutterSecureStorage.setMockInitialValues({'userId': 'u1'});
  final repo = FakePerfilRepo(
    user: user,
    failUser: failUser,
    restaurants: {
      'r1':
          Restaurant(id: 'r1', nombre: 'Casa Ángela', municipio: 'La Victoria'),
    },
  );
  await tester.pumpWidget(perfilApp(
    ValoracionesPage(repository: repo),
    userCubit: SeededUserCubit(repo, seed),
  ));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('listo: resumen, tarjetas y acción según haya texto',
      (tester) async {
    await _pump(
      tester,
      user: _user([
        Valoraciones(
          id: 'v1',
          rating: '4',
          title: 'Los churritos de pescado, de diez',
          review: 'Churritos de pescado y favada, todo casero.',
          valoracionesNegocioId: 'r1',
          restaurantes: Restaurantes(id: 'r1', nombre: 'Casa Ángela'),
        ),
        Valoraciones(
          id: 'v2',
          rating: '5',
          valoracionesNegocioId: 'r2',
          restaurantes: Restaurantes(id: 'r2', nombre: 'El Moral'),
        ),
      ]),
    );

    expect(find.text('Mis reseñas'), findsOneWidget);
    expect(byIdentifier('mis-resenas-stats'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('4,5'), findsOneWidget);
    expect(find.text('Casa Ángela'), findsOneWidget);
    expect(find.text('La Victoria'), findsOneWidget);
    expect(find.text('Muy buena'), findsOneWidget);
    expect(find.text('Los churritos de pescado, de diez'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    // Sin la ficha descargada se pinta con el nombre del perfil.
    expect(find.text('El Moral'), findsOneWidget);
    expect(find.text('Añadir texto'), findsOneWidget);
    expect(find.textContaining('Solo pusiste estrellas'), findsOneWidget);
  });

  testWidgets('vacío: invita a explorar', (tester) async {
    await _pump(tester, user: _user(const []));
    expect(byIdentifier('mis-resenas-empty'), findsOneWidget);
    expect(find.text('Aún no has escrito ninguna reseña'), findsOneWidget);
    expect(byIdentifier('mis-resenas-explore-button'), findsOneWidget);
  });

  testWidgets('error sin datos y reintento', (tester) async {
    final repo = await _pump(tester, user: _user(const []), failUser: true);
    expect(byIdentifier('mis-resenas-error'), findsOneWidget);

    repo.failUser = false;
    await tester.tap(byIdentifier('mis-resenas-retry-button'));
    await tester.pumpAndSettle();
    expect(byIdentifier('mis-resenas-error'), findsNothing);
    expect(byIdentifier('mis-resenas-empty'), findsOneWidget);
  });

  testWidgets('con datos previos, un fallo de red no tapa la lista',
      (tester) async {
    final user = _user([
      Valoraciones(
          id: 'v1', rating: '3', review: 'Bien', valoracionesNegocioId: 'r1'),
    ]);
    await _pump(tester, user: user, failUser: true, seed: UserLoaded(user));
    expect(byIdentifier('mis-resenas-error'), findsNothing);
    expect(byIdentifier('mis-resenas-card-v1'), findsOneWidget);
  });
}
