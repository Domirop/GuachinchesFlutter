import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/discover/discover_logic.dart';
import 'package:guachinches/ui/pages/discover/visit_filter_logic.dart';
import 'package:guachinches/ui/pages/discover/visit_sentiment.dart';
import 'package:guachinches/ui/pages/discover/widgets/sort_sheet.dart';
import 'package:guachinches/utils/contextual_pool.dart';

Visit _v(
  String id, {
  String? sentiment,
  String? type,
  String municipio = '',
  String? priceRange,
  double? priceApprox,
  bool photo = false,
}) {
  final r = Restaurant(id: 'r-$id', nombre: 'Sitio $id');
  r.municipio = municipio;
  if (type != null) r.type = type;
  return Visit(
    id: id,
    restaurantId: 'r-$id',
    overallSentiment: sentiment,
    priceRange: priceRange,
    priceApprox: priceApprox,
    dishes: [
      VisitDish(name: 'Plato', photoUrl: photo ? 'https://x/p.jpg' : null)
    ],
  )..restaurant = r;
}

void main() {
  const trad = RestaurantTypeIds.guachinchesTradicionales;
  const bod = RestaurantTypeIds.bodegones;

  final visits = [
    _v('1',
        sentiment: 'muy_positivo',
        type: trad,
        municipio: 'SANTA URSULA',
        priceRange: r'$$',
        photo: true),
    _v('2',
        sentiment: 'muy_positivo',
        type: trad,
        municipio: 'La Orotava',
        priceApprox: 12),
    _v('3', sentiment: 'positivo', type: bod, municipio: 'La Orotava'),
    _v('4', sentiment: 'neutro', type: trad, priceRange: r'$$$$'),
  ];

  test('ánimo desde overallSentiment', () {
    expect(visitMoodOf('muy_positivo'), VisitMood.loved);
    expect(visitMoodOf('positive'), VisitMood.liked);
    expect(visitMoodOf('neutro'), VisitMood.regular);
    expect(visitMoodOf('negativo'), isNull);
    expect(VisitMood.loved.label, 'Les encantó');
  });

  test('precio desde priceRange o priceApprox', () {
    expect(visitPrice(visits[0]), VisitPrice.mid);
    expect(visitPrice(visits[1]), VisitPrice.low);
    expect(visitPrice(visits[2]), isNull);
    expect(visitPrice(visits[3]), VisitPrice.high);
    expect(VisitPrice.high.label, '€€€');
  });

  test('tipo de sitio y fotos', () {
    expect(visitTypeKind(visits[0]), ListThemeKind.tradicional);
    expect(visitTypeKind(visits[2]), ListThemeKind.bodegon);
    expect(visitHasDishPhotos(visits[0]), isTrue);
    expect(visitHasDishPhotos(visits[1]), isFalse);
  });

  test('recuentos facetados: la propia sección no cuenta', () {
    const f = VisitFilterValues(moods: {VisitMood.loved});
    final c = visitFacetCounts(visits, f, discoverShortMunicipio);
    expect(c.total, 2);
    // Ánimos: sin aplicar el propio filtro de ánimo.
    expect(c.moods[VisitMood.loved], 2);
    expect(c.moods[VisitMood.liked], 1);
    expect(c.moods[VisitMood.regular], 1);
    // Tipos: con el filtro de ánimo aplicado.
    expect(c.types[ListThemeKind.tradicional], 2);
    expect(c.types[ListThemeKind.bodegon], isNull);
    expect(c.photos, 1);
    expect(c.prices[VisitPrice.mid], 1);
    expect(c.prices[VisitPrice.low], 1);
    expect(c.noPrice, 0);
    expect(c.municipios.first, ('La Orotava', 1));
  });

  test('pista del vacío: el filtro que más devuelve al quitarlo', () {
    const f = VisitFilterValues(
        moods: {VisitMood.regular}, types: {ListThemeKind.bodegon});
    expect(visitFacetCounts(visits, f, discoverShortMunicipio).total, 0);
    final hint = visitEmptyHint(visits, f, discoverShortMunicipio);
    expect(hint, isNotNull);
    expect(hint!.count, 1);
    expect(visitEmptyHintText('Regular', 13),
        'Ninguna visita cumple todos los filtros. Quita «Regular» y verás 13 visitas.');
  });

  test('textos', () {
    expect(visitFilterTitle(0), 'Filtrar visitas');
    expect(visitFilterTitle(2), 'Filtrar visitas · 2');
    expect(visitFilterCta(82), 'Mostrar 82 visitas');
    expect(visitFilterCta(1), 'Mostrar 1 visita');
    expect(visitFilterCta(0), 'Ninguna visita con estos filtros');
    expect(visitPriceCaption(29),
        'El que dicen en el vídeo. 29 de estas visitas no lo mencionan.');
  });

  test('opciones de tipo en orden y órdenes según ubicación', () {
    expect(visitTypeOptions(visits, const VisitFilterValues()),
        [ListThemeKind.tradicional, ListThemeKind.bodegon]);
    expect(visitSortOptions(hasLocation: false),
        isNot(contains(VisitSort.nearest)));
    expect(visitSortOptions(hasLocation: true), contains(VisitSort.nearest));
    expect(VisitSort.alphaAsc.pillLabel, 'Por nombre');
  });
}
