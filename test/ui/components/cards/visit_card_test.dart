import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/model/user_visit.dart';
import 'package:guachinches/ui/components/cards/visit_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: appDarkTheme,
      home: Scaffold(body: child),
    );

UserVisit _makeVisit({
  String id = 'v1',
  String restaurantName = 'El Guachinche',
  int? rating,
  String? note,
  DateTime? visitedAt,
  String? photoUrl,
}) {
  return UserVisit(
    id: id,
    restaurantId: 'r1',
    restaurantName: restaurantName,
    restaurantPhotoUrl: photoUrl,
    visitedAt: visitedAt ?? DateTime.now().subtract(const Duration(days: 5)),
    rating: rating,
    note: note,
  );
}

void main() {
  group('VisitCard', () {
    testWidgets('(a) renders restaurantName', (tester) async {
      await tester.pumpWidget(
        _wrap(VisitCard(visit: _makeVisit(restaurantName: 'Casa Pepe'))),
      );
      await tester.pump();

      expect(find.text('Casa Pepe'), findsOneWidget);
    });

    testWidgets('(b) without rating there are no star icons', (tester) async {
      await tester.pumpWidget(
        _wrap(VisitCard(visit: _makeVisit(rating: null))),
      );
      await tester.pump();

      final icons = tester.widgetList<Icon>(find.byType(Icon));
      final starIcons = icons
          .where((i) => i.icon == Icons.star || i.icon == Icons.star_border)
          .toList();

      expect(starIcons, isEmpty);
    });

    testWidgets('(c) with rating 4, exactly 5 star icons (4 filled + 1 empty)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(VisitCard(visit: _makeVisit(rating: 4))),
      );
      await tester.pump();

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      final filled = icons.where((i) => i.icon == Icons.star).length;
      final empty = icons.where((i) => i.icon == Icons.star_border).length;

      expect(filled + empty, 5);
      expect(filled, 4);
      expect(empty, 1);
    });

    testWidgets('(d) without note there is no extra note text widget',
        (tester) async {
      await tester.pumpWidget(
        _wrap(VisitCard(visit: _makeVisit(note: null))),
      );
      await tester.pump();

      // The only text visible should be the restaurant name and the relative date.
      // There should be no text with 2-line overflow that could be the note.
      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts.length, 2); // name + relative date
    });

    testWidgets('(e) relative age string contains "hace" for past visitedAt',
        (tester) async {
      final pastDate = DateTime.now().subtract(const Duration(days: 10));
      await tester.pumpWidget(
        _wrap(VisitCard(visit: _makeVisit(visitedAt: pastDate))),
      );
      await tester.pump();

      expect(find.textContaining('hace'), findsOneWidget);
    });
  });
}
