import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/dish_viewer_logic.dart';

void main() {
  group('dishStampFor', () {
    test('les encantó: loved y muy positivo', () {
      expect(dishStampFor(sentiment: 'loved'), DishStamp.loved);
      expect(dishStampFor(sentiment: 'muy_positivo'), DishStamp.loved);
      expect(dishStampFor(sentiment: ' LOVED '), DishStamp.loved);
    });
    test('no les convenció: disliked y negativos', () {
      for (final s in ['disliked', 'negative', 'negativo', 'muy_negativo']) {
        expect(dishStampFor(sentiment: s), DishStamp.disliked, reason: s);
      }
    });
    test('neutro, les gustó o desconocido: sin sello', () {
      for (final s in ['liked', 'positivo', 'neutral', 'neutro', 'raro']) {
        expect(dishStampFor(sentiment: s), DishStamp.none, reason: s);
      }
      expect(dishStampFor(), DishStamp.none);
    });
    test('top sin sentimiento cuenta como «Les encantó»; con sentimiento no',
        () {
      expect(dishStampFor(isTop: true), DishStamp.loved);
      expect(dishStampFor(sentiment: 'liked', isTop: true), DishStamp.none);
      expect(dishStampOf(const VisitDish(name: 'x', isTop: true)),
          DishStamp.loved);
    });
  });

  test('dishPriceLabel', () {
    expect(dishPriceLabel(26), '26 €');
    expect(dishPriceLabel(26.0), '26 €');
    expect(dishPriceLabel(12.5), '12,50 €');
    expect(dishPriceLabel(null), isNull);
    expect(dishPriceLabel(0), isNull);
  });

  test('dishViewerCounter', () {
    expect(dishViewerCounter(4, 6), '5 / 6');
  });

  test('dishViewerFooter: sitio y fecha, lo que haya', () {
    expect(
        dishViewerFooter(
            placeName: 'Casa Ángela', visitDateIso: '2026-10-08T12:00:00Z'),
        'Casa Ángela · Visita del 8 oct 2026');
    expect(dishViewerFooter(placeName: 'Casa Ángela'), 'Casa Ángela');
    expect(dishViewerFooter(visitDateIso: '2026-10-07T12:00:00Z'),
        'Visita del 7 oct 2026');
    expect(dishViewerFooter(placeName: ' ', visitDateIso: 'x'), isNull);
  });

  test('dishViewerPlaceName: restaurante y si no, la visita', () {
    expect(
        dishViewerPlaceName(Visit(
            id: 'v',
            restaurantId: 'r',
            restaurant: Restaurant(id: 'r', nombre: 'CASA ÁNGELA'))),
        'Casa Ángela');
    expect(
        dishViewerPlaceName(
            Visit(id: 'v', restaurantId: 'r', name: 'El Moral')),
        'El Moral');
    expect(dishViewerPlaceName(Visit(id: 'v', restaurantId: 'r')), isNull);
  });

  test('dishShareText', () {
    expect(
        dishShareText(
            dishName: 'Conejo',
            placeName: 'Casa Ángela',
            photoUrl: 'https://cdn/4.jpg'),
        'Conejo en Casa Ángela\nhttps://cdn/4.jpg');
    expect(dishShareText(dishName: 'Conejo'), 'Conejo');
  });

  group('dishThumbOffset', () {
    test('si la tira cabe, no se desplaza', () {
      expect(dishThumbOffset(index: 5, count: 6, viewport: 402), 0);
    });
    test('centra la actual y se acota a los extremos', () {
      // 7 miniaturas: 16·2 + 7·52 + 6·10 = 456 de contenido en 402.
      expect(dishThumbOffset(index: 0, count: 7, viewport: 402), 0);
      expect(dishThumbOffset(index: 3, count: 7, viewport: 402),
          closeTo(16 + 3 * 62 + 26 - 201, 0.001));
      expect(dishThumbOffset(index: 6, count: 7, viewport: 402), 54);
    });
  });
}
