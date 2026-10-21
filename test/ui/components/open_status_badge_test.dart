import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/ui/components/open_status_badge.dart';

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

Map<String, dynamic> _allDay(String open, String close) => {
      'periods': [
        for (var d = 0; d <= 6; d++)
          {
            'open': {'day': d, 'time': open},
            'close': {'day': d, 'time': close},
          }
      ]
    };

void main() {
  testWidgets('sin horario fiable: neutro, nunca «Cerrado»', (tester) async {
    await tester.pumpWidget(_app(
        const OpenStatusBadge(horariosJson: null, fallbackOpen: false)));
    await tester.pumpAndSettle();
    expect(find.text('Horario sin confirmar'), findsOneWidget);
    expect(find.text('Cerrado'), findsNothing);
  });

  testWidgets('sin horario pero el backend dice abierto: «Abierto»',
      (tester) async {
    await tester.pumpWidget(
        _app(const OpenStatusBadge(horariosJson: null, fallbackOpen: true)));
    await tester.pumpAndSettle();
    expect(find.text('Abierto'), findsOneWidget);
  });

  testWidgets('abierto todo el día y cerrado todo el día', (tester) async {
    await tester.pumpWidget(_app(OpenStatusBadge(
        horariosJson: _allDay('0000', '2359'), fallbackOpen: false)));
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp('Abierto|Cierra en')), findsOneWidget);
  });
}
