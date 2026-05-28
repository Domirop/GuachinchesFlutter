import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/favoritos/favorito_detail_screen.dart';

void main() {
  final fakeRestaurant = Restaurant(
    id: 'rest-42',
    nombre: 'Guachinche de Prueba',
    avgRating: 4.2,
    municipio: 'La Laguna',
    mainFoto: '',
  );

  testWidgets('muestra el nombre del restaurante', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appDarkTheme,
        home: FavoritoDetailScreen(restaurant: fakeRestaurant),
      ),
    );
    await tester.pump();

    expect(find.text('Guachinche de Prueba'), findsOneWidget);
  });

  testWidgets('tras tocar favorito-detail-remove-button aparece AlertDialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appDarkTheme,
        home: FavoritoDetailScreen(restaurant: fakeRestaurant),
      ),
    );
    await tester.pump();

    final removeBtn = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == 'favorito-detail-remove-button',
    );
    expect(removeBtn, findsOneWidget);

    await tester.tap(removeBtn);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('tras tocar favorito-detail-confirm-remove-button la pantalla cierra con true', (tester) async {
    bool? popResult;

    await tester.pumpWidget(
      MaterialApp(
        theme: appDarkTheme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              popResult = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => FavoritoDetailScreen(restaurant: fakeRestaurant),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final removeBtn = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == 'favorito-detail-remove-button',
    );
    await tester.tap(removeBtn);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    final confirmBtn = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == 'favorito-detail-confirm-remove-button',
    );
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(popResult, true);
  });
}
