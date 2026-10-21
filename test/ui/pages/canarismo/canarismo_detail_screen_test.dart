import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/canarismos.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_detail_screen.dart';
import 'package:guachinches/ui/pages/canarismo/canarismo_story_sheet.dart';

void main() {
  final today = DateTime(2026, 10, 14); // miércoles; palabra «Tasca»

  Future<void> pump(WidgetTester tester, Widget home,
      {Brightness brightness = Brightness.light}) async {
    tester.view.physicalSize = const Size(1206, 2622); // iPhone 16 Pro @3x
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: home,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('hoy: «El canarismo del día» + cinco anteriores', (tester) async {
    await pump(
      tester,
      CanarismoDetailScreen(initial: canarismoOfDay(today), today: today),
    );
    expect(tester.takeException(), isNull);
    expect(
        find.bySemanticsIdentifier('canarismo-detail-screen'), findsOneWidget);
    expect(find.text('El canarismo del día · miércoles 14 de octubre'),
        findsOneWidget);
    expect(find.text('Tasca'), findsWidgets);
    expect(find.text('Comparte el canarismo'), findsOneWidget);
    expect(find.text('Los últimos cinco días'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      expect(find.bySemanticsIdentifier('canarismo-detail-history-row-$i'),
          findsOneWidget);
    }
    expect(find.text('Ayer'), findsOneWidget);
    expect(find.text('Gofio'), findsOneWidget);
    expect(find.bySemanticsIdentifier('canarismo-detail-back'), findsOneWidget);
    expect(
        find.bySemanticsIdentifier('canarismo-detail-share'), findsOneWidget);
    expect(find.bySemanticsIdentifier('canarismo-detail-create-card'),
        findsOneWidget);
  });

  testWidgets('día pasado: sin «del día» y etiquetas respecto a hoy',
      (tester) async {
    final past = DateTime(2026, 10, 12);
    await pump(
      tester,
      CanarismoDetailScreen(
          initial: canarismoOfDay(past), date: past, today: today),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Canarismo · lunes 12 de octubre'), findsOneWidget);
    expect(find.textContaining('del día'), findsNothing);
    expect(find.text('Los cinco días anteriores'), findsOneWidget);
    // 11 oct = hace 3 días respecto al 14.
    expect(find.text('Hace 3 días'), findsOneWidget);
    expect(find.text('Ayer'), findsNothing);
  });

  testWidgets('tocar una fila abre ese canarismo (sin «del día»)',
      (tester) async {
    await pump(
      tester,
      CanarismoDetailScreen(initial: canarismoOfDay(today), today: today),
    );
    final row = find.bySemanticsIdentifier('canarismo-detail-history-row-0');
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Canarismo · martes 13 de octubre'), findsOneWidget);
  });

  testWidgets('«Crear tarjeta» abre la hoja de la tarjeta para historias',
      (tester) async {
    await pump(
      tester,
      CanarismoDetailScreen(initial: canarismoOfDay(today), today: today),
      brightness: Brightness.dark,
    );
    await tester
        .tap(find.bySemanticsIdentifier('canarismo-detail-create-card'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CanarismoStorySheet), findsOneWidget);
    expect(find.text('Tarjeta para historias'), findsOneWidget);
    expect(find.bySemanticsIdentifier('canarismo-card-sheet-save'),
        findsOneWidget);
    expect(find.bySemanticsIdentifier('canarismo-card-sheet-share'),
        findsOneWidget);
    await tester.tap(find.bySemanticsIdentifier('canarismo-card-sheet-close'));
    await tester.pumpAndSettle();
    expect(find.byType(CanarismoStorySheet), findsNothing);
  });

  testWidgets('palabra larga y texto grande no desbordan', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(
      tester,
      CanarismoDetailScreen(
        initial: const Canarismo('Pasar más hambre que un maestro',
            'Tener muchísima hambre; pasar grandes penurias económicas.'),
        today: today,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
