import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/pages/visit/visit_dishes_screen.dart';
import 'package:guachinches/ui/pages/visit/visit_screen.dart';
import 'package:video_player/video_player.dart';

class _Loc extends LocationCubit {
  _Loc() {
    emit(LocationDenied());
  }
}

Visit _visit() => Visit(
      id: 'v1',
      restaurantId: '',
      name: 'Autobar del Arco de Tajao',
      zone: 'Arico',
      videoPublishedAt: '2026-03-10T12:58:49Z',
      durationSeconds: 130,
      overallSentiment: 'muy_positivo',
      dishes: const [
        VisitDish(name: 'Arepas de cochino', sentiment: 'loved', isTop: true),
        VisitDish(name: 'Bocadillos de cochino', sentiment: 'loved', isTop: true),
      ],
      quotes: const [
        VisitQuote(text: 'Qué buenas están las arepas aquí.', sentiment: 'positive'),
      ],
    );

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  for (final scale in [1.0, 2.0]) {
    testWidgets(
        'reel: texto sobre el vídeo, tira de platos y hoja que se despliega '
        '(texto ${scale}x)', (tester) async {
      tester.view.physicalSize = const Size(1206, 2622);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(BlocProvider<LocationCubit>(
        create: (_) => _Loc(),
        child: MaterialApp(
          theme: appLightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          VisitDetailPage(visitId: 'v1', initialVisit: _visit()),
                    ),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(seconds: 3));

      // Sobre el vídeo: autores + fecha + duración, el sitio, sello y cita.
      expect(find.textContaining('Jonay y Joana', findRichText: true),
          findsOneWidget);
      expect(find.textContaining('10 mar 2026 · 2:10', findRichText: true),
          findsOneWidget);
      expect(find.text('Autobar del Arco de Tajao'), findsOneWidget);
      expect(find.text('Les encantó'), findsOneWidget);
      expect(find.text('«Qué buenas están las arepas aquí.»'), findsOneWidget);
      // Sin minuto conocido, sin pie inventado.
      expect(find.textContaining('Minuto'), findsNothing);
      // Tira de platos y asa de la hoja.
      expect(find.text('Arepas de cochino'), findsWidgets);
      expect(find.text('Desliza para ver los platos y el sitio'), findsOneWidget);
      expect(find.bySemanticsLabel('Cerrar'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Arrastrar la hoja hacia arriba: aparece «Lo que probaron».
      await tester.drag(find.text('Desliza para ver los platos y el sitio'),
          const Offset(0, -700));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('Lo que probaron'), findsOneWidget);
      expect(find.text('2 platos · 2 les encantaron'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Platos sin foto: el hueco con el glifo (tira y rejilla de la hoja).
      expect(find.byType(GmDishNoPhoto), findsNWidgets(4));

      // Atrás (botón del sistema) con la hoja abierta: la pliega y sigue en
      // el reel.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('Desliza para ver los platos y el sitio'), findsOneWidget);
      expect(find.text('abrir'), findsNothing);

      // Gesto de volver desde el borde izquierdo con la hoja abierta: también
      // la pliega.
      await tester.drag(find.text('Desliza para ver los platos y el sitio'),
          const Offset(0, -700));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('Desliza para volver al vídeo'), findsOneWidget);
      await tester.dragFrom(const Offset(4, 300), const Offset(220, 0));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('Desliza para ver los platos y el sitio'), findsOneWidget);
      expect(find.text('abrir'), findsNothing);

      // Plegada, Cerrar sale del reel.
      await tester.tap(find.bySemanticsLabel('Cerrar'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('abrir'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  test('minuto de una cita: solo si el backend lo da', () {
    expect(visitMinute('00:01:48'), '1:48');
    expect(visitMinute('72'), '1:12');
    expect(visitMinute(null), isNull);
    final v = Visit(id: 'a', restaurantId: 'r', quotes: const [
      VisitQuote(text: 'Son caseritos.', timestamp: '0:42'),
    ]);
    expect(visitReelQuote(v), (text: '«Son caseritos.»', caption: 'Minuto 0:42'));
  });

  testWidgets('barra de historia: un solo tramo con el avance del vídeo',
      (tester) async {
    final progress = ValueNotifier(const VideoPlayerValue(
      duration: Duration(seconds: 100),
      position: Duration(seconds: 25),
    ));
    addTearDown(progress.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: VisitStoryProgress(progress: progress)),
    ));
    final bars = tester
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .toList();
    expect(bars, hasLength(1));
    expect(bars.single.widthFactor, closeTo(0.25, 0.001));

    progress.value = progress.value.copyWith(position: const Duration(seconds: 100));
    await tester.pump();
    expect(
        tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        1.0);
  });
}
