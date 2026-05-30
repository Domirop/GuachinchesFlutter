import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/ui/components/section_header.dart';
import 'package:guachinches/utils/distance_utils.dart';

// Sub-widget equivalent: mirrors the nearby header construction in NewHomeBody.
// Renders SectionHeader with the same conditional actionLabel/onAction logic.
class _NearbyHeaderUnderTest extends StatelessWidget {
  final List<NearbyRestaurant> nearbyList;
  final VoidCallback? onShowAllNearby;

  const _NearbyHeaderUnderTest({
    required this.nearbyList,
    this.onShowAllNearby,
  });

  @override
  Widget build(BuildContext context) {
    if (nearbyList.isEmpty) return const SizedBox.shrink();
    return SectionHeader(
      title: AppL10n.of(context).homeNearbySectionTitle.toUpperCase(),
      actionLabel: onShowAllNearby != null
          ? AppL10n.of(context).homeSeeAll.toUpperCase()
          : null,
      onAction: onShowAllNearby,
    );
  }
}

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      theme: ThemeData.dark().copyWith(extensions: const [BrandColors.dark]),
      home: Scaffold(body: child),
    );

Finder _bySemanticsId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

NearbyRestaurant _stubNearby() => NearbyRestaurant(
      restaurant: Restaurant(id: 'r1', nombre: 'Test'),
      distanceLabel: '1 km',
    );

void main() {
  group('NearbyHeader — onShowAllNearby wire', () {
    testWidgets(
      '(1) with onShowAllNearby: section-header-cta found, tap invokes callback once',
      (tester) async {
        int calls = 0;
        await tester.pumpWidget(
          _wrap(
            _NearbyHeaderUnderTest(
              nearbyList: [_stubNearby()],
              onShowAllNearby: () => calls++,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final cta = _bySemanticsId('section-header-cta');
        expect(cta, findsOneWidget);

        await tester.tap(cta);
        await tester.pump();

        expect(calls, 1);
      },
    );

    testWidgets(
      '(2) with onShowAllNearby == null: section-header-cta not found',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            _NearbyHeaderUnderTest(
              nearbyList: [_stubNearby()],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_bySemanticsId('section-header-cta'), findsNothing);
      },
    );
  });
}
