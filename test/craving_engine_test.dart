import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/domain/cravings/craving_catalog.dart';
import 'package:guachinches/domain/cravings/craving_context.dart';
import 'package:guachinches/domain/cravings/craving_engine.dart';

/// Tests del motor de "¿Qué te apetece?". Dominio puro → sin Flutter binding.
void main() {
  List<String> ids(CravingContext ctx, {int max = 4}) =>
      rankCravings(kCravingCatalog, ctx, max: max).map((c) => c.id).toList();

  group('bandas de contexto', () {
    test('franja horaria', () {
      expect(dayPartFromHour(3), DayPart.madrugada);
      expect(dayPartFromHour(9), DayPart.desayuno);
      expect(dayPartFromHour(13), DayPart.mediodia);
      expect(dayPartFromHour(15), DayPart.sobremesa);
      expect(dayPartFromHour(18), DayPart.tarde);
      expect(dayPartFromHour(22), DayPart.noche);
    });

    test('temperatura', () {
      expect(tempBandFromCelsius(null), TempBand.unknown);
      expect(tempBandFromCelsius(12), TempBand.cold);
      expect(tempBandFromCelsius(20), TempBand.mild);
      expect(tempBandFromCelsius(26), TempBand.warm);
      expect(tempBandFromCelsius(30), TempBand.hot);
    });

    test('condition del backend → Sky', () {
      expect(skyFromCondition('sunny'), Sky.clear);
      expect(skyFromCondition('rain'), Sky.rain);
      expect(skyFromCondition('???'), Sky.unknown);
    });
  });

  group('ranking contextual', () {
    test('mañana ⇒ desayuno manda', () {
      const ctx = CravingContext(
        dayPart: DayPart.desayuno,
        sky: Sky.clear,
        tempBand: TempBand.mild,
        dayType: DayType.weekday,
        hour: 9,
      );
      expect(ids(ctx).first, 'desayuno');
    });

    test('mediodía lluvioso y frío ⇒ de cuchara manda; terraza no sale', () {
      const ctx = CravingContext(
        dayPart: DayPart.mediodia,
        sky: Sky.rain,
        tempBand: TempBand.cold,
        dayType: DayType.weekend,
        hour: 13,
      );
      final top = ids(ctx);
      expect(top.first, 'cuchara');
      expect(top, isNot(contains('terraza')));
    });

    test('viernes tarde soleado y calor ⇒ terraza arriba, atardecer presente', () {
      const ctx = CravingContext(
        dayPart: DayPart.tarde,
        sky: Sky.clear,
        tempBand: TempBand.warm,
        dayType: DayType.friday,
        hour: 19,
      );
      final top = ids(ctx);
      expect(top.first, 'terraza');
      expect(top, contains('atardecer'));
    });

    test('noche ⇒ cenar entra en el top', () {
      const ctx = CravingContext(
        dayPart: DayPart.noche,
        sky: Sky.clouds,
        tempBand: TempBand.mild,
        dayType: DayType.weekday,
        hour: 22,
      );
      expect(ids(ctx), contains('cena'));
    });
  });

  group('garantías del motor', () {
    test('nunca vacío y respeta max', () {
      for (final dp in DayPart.values) {
        final ctx = CravingContext(
          dayPart: dp,
          sky: Sky.unknown,
          tempBand: TempBand.unknown,
          dayType: DayType.weekday,
          hour: 12,
        );
        final r = rankCravings(kCravingCatalog, ctx, max: 4);
        expect(r, isNotEmpty, reason: 'franja $dp');
        expect(r.length, lessThanOrEqualTo(4));
      }
    });

    test('diversidad: sin familias repetidas con perFamily=1', () {
      const ctx = CravingContext(
        dayPart: DayPart.tarde,
        sky: Sky.clear,
        tempBand: TempBand.warm,
        dayType: DayType.weekend,
        hour: 18,
      );
      final picked = rankCravings(kCravingCatalog, ctx, max: 4, perFamily: 1);
      final fams = picked.map((c) => c.family).toList();
      expect(fams.toSet().length, fams.length, reason: 'familias únicas');
    });

    test('determinista: mismo contexto → misma salida', () {
      const ctx = CravingContext(
        dayPart: DayPart.mediodia,
        sky: Sky.clear,
        tempBand: TempBand.warm,
        dayType: DayType.weekday,
        hour: 13,
      );
      expect(ids(ctx), ids(ctx));
    });
  });
}
