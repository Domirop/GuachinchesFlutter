import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/ui/Others/new_review/new_review.dart';
import 'package:guachinches/ui/pages/valoraciones/valoracion_detail_screen.dart';
import 'package:http/http.dart' as http;

void main() {
  final fakeValoracion = Valoraciones(
    id: 'v1',
    review: 'Excelente lugar con buena comida canaria tradicional.',
    title: 'Una visita inolvidable',
    rating: '4',
    valoracionesNegocioId: 'rest-1',
    valoracionesUsuarioId: 'user-1',
    restaurantes: Restaurantes(
      id: 'rest-1',
      nombre: 'El Guachinche de Prueba',
      direccion: 'Calle Falsa 123',
    ),
  );

  Widget buildSut() => BlocProvider(
        create: (_) => RestaurantCubit(HttpRemoteRepository(http.Client())),
        child: MaterialApp(
          theme: appDarkTheme,
          home: ValoracionDetailScreen(valoracion: fakeValoracion),
        ),
      );

  testWidgets('muestra el título y el texto completo de la reseña', (tester) async {
    await tester.pumpWidget(buildSut());
    await tester.pump();

    expect(find.text('Una visita inolvidable'), findsOneWidget);
    expect(find.text('Excelente lugar con buena comida canaria tradicional.'), findsOneWidget);
  });

  testWidgets('pinta exactamente 4 estrellas llenas y 1 vacía para rating=4', (tester) async {
    await tester.pumpWidget(buildSut());
    await tester.pump();

    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    final filledStars = icons
        .where((i) => i.icon == Icons.star_rounded && i.color == AppColors.sol)
        .length;
    final emptyStars = icons
        .where((i) => i.icon == Icons.star_outline_rounded && i.color == AppColors.sol)
        .length;

    expect(filledStars, 4);
    expect(emptyStars, 1);
  });

  testWidgets('al tocar valoracion-detail-edit-button aparece NewReview en el árbol', (tester) async {
    await tester.pumpWidget(buildSut());
    await tester.pump();

    final editBtn = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == 'valoracion-detail-edit-button',
    );
    expect(editBtn, findsOneWidget);

    await tester.tap(editBtn);
    await tester.pumpAndSettle();
    // NewReview uses NetworkImage("") which fails in tests; clear the image exception.
    tester.takeException();

    expect(find.byType(NewReview), findsOneWidget);
  });
}
