import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/ui/components/vignettes/list_vignette.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/curated_list_detail/curated_list_logic.dart';

CuratedListItem item(String id, int pos,
        {String? nombre, String? muni, String? foto, String? note}) =>
    CuratedListItem(
      restaurantId: id,
      position: pos,
      note: note,
      restaurant: CuratedListItemRestaurant(
          id: id, nombre: nombre ?? id, municipio: muni, mainFoto: foto),
    );

Visit visit(String id, String restaurantId,
        {String? date,
        List<String> dishes = const [],
        double? price,
        String? poster}) =>
    Visit(
      id: id,
      restaurantId: restaurantId,
      videoPublishedAt: date,
      posterUrl: poster,
      priceApprox: price,
      dishes: [for (final d in dishes) VisitDish(name: d)],
    );

void main() {
  group('tema y textos de la cabecera', () {
    test('cada viñeta con su tema de lista', () {
      expect(curatedThemeKind(ListVignetteKind.bocadillo), ListThemeKind.tasca);
      expect(curatedThemeKind(ListVignetteKind.japones), ListThemeKind.lounge);
      expect(curatedThemeKind(ListVignetteKind.celebracion),
          ListThemeKind.experiencia);
      expect(curatedThemeKind(ListVignetteKind.brunch), ListThemeKind.bar);
      expect(curatedThemeKind(null), ListThemeKind.categoria);
    });

    test('antetítulo en caja normal con el nº de sitios y la isla', () {
      expect(curatedHeaderEyebrow('TOP', 7, 'Tenerife'), 'Top · 7 en Tenerife');
      expect(curatedHeaderEyebrow('GUÍA', 6, null), 'Guía · 6 sitios');
      expect(curatedHeaderEyebrow('Cenas especiales', 3, 'Tenerife'),
          'Cenas especiales · 3 en Tenerife');
      expect(curatedHeaderEyebrow('', 1, null), '1 sitio');
    });
  });

  group('datos de la tarjeta', () {
    test('municipio corto y precio aproximado', () {
      expect(shortMunicipio('San Cristóbal de La Laguna'), 'La Laguna');
      expect(shortMunicipio('SANTA CRUZ DE TENERIFE'), 'Santa Cruz');
      expect(shortMunicipio('Arafo'), 'Arafo');
      expect(formatPriceApprox(11), '≈ 11 €');
      expect(formatPriceApprox(11.6), '≈ 11,60 €');
      expect(formatPriceApprox(null), isNull);
      expect(formatPriceApprox(0), isNull);
    });

    test('se cruza con la visita más reciente del sitio', () {
      final places = curatedPlaces([
        item('a', 2, nombre: 'BAR CHICHO', muni: 'Arafo', foto: 'local.jpg'),
        item('b', 1,
            nombre: 'Sin vídeo', foto: 'b.jpg', note: 'Nota de la guía'),
      ], [
        visit('v1', 'a', date: '2025-01-01', dishes: ['Viejo']),
        visit('v2', 'a',
            date: '2025-03-15',
            dishes: ['bocadillo de cochino', 'Barraquito'],
            price: 12,
            poster: 's3/poster.jpg'),
      ]);

      // Orden de la guía (position) y puesto 1-based.
      expect(places.map((p) => p.restaurantId), ['b', 'a']);
      expect(places.map((p) => p.rank), [1, 2]);

      final chicho = places[1];
      expect(chicho.visit!.id, 'v2');
      expect(chicho.name, 'Bar Chicho');
      expect(chicho.note, 'Bocadillo de cochino');
      expect(chicho.zone, 'Arafo');
      expect(chicho.price, '≈ 12 €');
      expect(chicho.hasVideo, isTrue);
      expect(chicho.photo, 's3/poster.jpg');
      expect(chicho.photoFallbacks.last, 'local.jpg');

      final sinVideo = places[0];
      expect(sinVideo.hasVideo, isFalse);
      expect(sinVideo.note, 'Nota de la guía');
      expect(sinVideo.photo, 'b.jpg');
      expect(sinVideo.price, isNull);
    });
  });

  group('búsqueda, zonas y orden', () {
    final places = curatedPlaces([
      item('a', 1, nombre: 'Nintai', muni: 'San Cristóbal de La Laguna'),
      item('b', 2, nombre: 'Ávila Tei', muni: 'Puerto de la Cruz'),
      item('c', 3, nombre: 'NaNa Sushi', muni: 'Santa Cruz de Tenerife'),
    ], [
      visit('v', 'c', dishes: ['Tartar de atún']),
    ]);

    test('busca sin tildes en nombre, zona y platos del vídeo', () {
      expect(
          filterCuratedPlaces(places, query: 'avila')
              .map((p) => p.restaurantId),
          ['b']);
      expect(
          filterCuratedPlaces(places, query: 'laguna')
              .map((p) => p.restaurantId),
          ['a']);
      expect(
          filterCuratedPlaces(places, query: 'atun tartar')
              .map((p) => p.restaurantId),
          ['c']);
      expect(filterCuratedPlaces(places, query: 'pizza'), isEmpty);
    });

    test('filtra por zona y ordena de la A a la Z', () {
      expect(curatedZones(places),
          ['La Laguna', 'Puerto de la Cruz', 'Santa Cruz']);
      expect(
          filterCuratedPlaces(places, zone: 'Santa Cruz').single.restaurantId,
          'c');
      expect(
          filterCuratedPlaces(places, sort: CuratedSort.alphabetical)
              .map((p) => p.name),
          ['Ávila Tei', 'NaNa Sushi', 'Nintai']);
    });

    test('con una sola zona no hay filtro de zonas', () {
      expect(curatedZones(places.take(1).toList()), isEmpty);
    });
  });
}
