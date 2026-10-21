import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/cubit/new_home/weather_cubit.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/services/weather_service.dart';
import 'package:guachinches/ui/pages/new_home/widgets/parallax_hero.dart';

class _NoWeather extends Fake implements WeatherService {}

/// QA multidispositivo (I4): la fila «HOY [TENERIFE ▾] ?» desbordaba 35 px
/// en el iPhone SE con texto grande y 19 px en el Nexus S al 130 %.
void main() {
  for (final (w, h, scale) in [
    (375.0, 667.0, 1.35), // iPhone SE, accessibility-medium
    (320.0, 533.0, 1.3), // Nexus S
    (320.0, 533.0, 2.0),
  ]) {
    testWidgets('hero sin desbordes a ${w.toInt()} pt y texto ${scale}x',
        (tester) async {
      tester.view.physicalSize = Size(w * 2, h * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BlocProvider<WeatherCubit>(
        create: (_) => WeatherCubit(_NoWeather()),
        child: MaterialApp(
          theme: appLightTheme,
          locale: const Locale('es'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          builder: (ctx, c) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(
                textScaler: TextScaler.linear(scale), disableAnimations: true),
            child: c!,
          ),
          home: Scaffold(
            body: ParallaxHero(
              scrollOffset: 0,
              hour: 13,
              zona: 'Gran Canaria',
              islandLabel: 'Gran Canaria',
              zoneIsSet: false,
              openCount: 144,
              onZoneChipTap: () {},
              onIslandChipTap: () {},
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.text('HOY '), findsOneWidget);
    });
  }
}
