import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/onboarding_flow/onboarding_logic.dart';

ModelCategory _cat(String id, String nombre) =>
    ModelCategory(id: id, nombre: nombre, iconUrl: '', foto: '');

/// Nombres tal cual llegan de `/categorias` (17).
final kRealCategories = [
  _cat('1', 'Carne cabra'),
  _cat('2', 'COCHINO NEGRO'),
  _cat('3', 'Pescado o marisco'),
  _cat('4', 'Papas, piñas y costillas'),
  _cat('5', 'Puchero'),
  _cat('6', 'Cosecha propia'),
  _cat('7', 'Sin gluten'),
  _cat('8', 'Con V'),
  _cat('9', 'Terraza'),
  _cat('10', 'Con vistas'),
  _cat('11', 'Mercado'),
  _cat('12', 'Experiencia'),
  _cat('13', 'Datáfono'),
  _cat('14', 'Acceso PMR'),
  _cat('15', 'Permite mascotas'),
  _cat('16', 'Animales'),
  _cat('17', 'Zona infantil'),
];

void main() {
  group('gustos', () {
    test('las 17 categorías reales se reagrupan con nombres limpios', () {
      final g = onbGroupTastes(kRealCategories);
      expect(g.keys.toList(), [
        OnbTasteGroup.food,
        OnbTasteGroup.plans,
        OnbTasteGroup.services,
      ]);
      expect(g[OnbTasteGroup.food]!.map((t) => t.label).toList(), [
        'Carne de cabra',
        'Cochino negro',
        'Pescado o marisco',
        'Papas, piña y costillas',
        'Puchero',
        'Cosecha propia',
        'Sin gluten',
        'Con V',
      ]);
      expect(g[OnbTasteGroup.plans]!.map((t) => t.label).toList(),
          ['Terraza', 'Con vistas', 'Mercado', 'Experiencia']);
      expect(g[OnbTasteGroup.services]!.map((t) => t.label).toList(), [
        'Datáfono',
        'Accesible',
        'Admite mascotas',
        'Con animales',
        'Zona infantil',
      ]);
      // Se guarda el id real, no la etiqueta.
      expect(g[OnbTasteGroup.services]!.first.id, '13');
    });

    test('«Animales» no se confunde con «Admite mascotas»', () {
      expect(onbTasteFor(_cat('a', 'Animales')).label, 'Con animales');
      expect(
          onbTasteFor(_cat('b', 'Permite mascotas')).label, 'Admite mascotas');
    });

    test('una categoría nueva cae en «Me gusta comer» al final, sin emoji', () {
      final g = onbGroupTastes([_cat('x', 'TAPAS'), ...kRealCategories]);
      final food = g[OnbTasteGroup.food]!;
      expect(food.last.label, 'Tapas');
      expect(food.last.glyph, OnbTasteGlyph.plato);
    });

    test('sin duplicados de etiqueta ni categorías vacías', () {
      final g = onbGroupTastes(
          [_cat('1', 'Terraza'), _cat('2', 'TERRAZA'), _cat('', 'Puchero')]);
      expect(g.length, 1);
      expect(g[OnbTasteGroup.plans]!.single.id, '1');
    });

    test('mínimo 3: «Elige N más» y contador', () {
      expect(onbTastesCta(0), 'Elige 3 más');
      expect(onbTastesCta(2), 'Elige 1 más');
      expect(onbTastesCta(3), 'Continuar');
      expect(onbTastesCounter(0), '');
      expect(onbTastesCounter(1), '1 elegido');
      expect(onbTastesCounter(4), '4 elegidos');
    });
  });

  group('isla', () {
    test('ordena por position y usa la key como insignia', () {
      final list = onbSortedIslands([
        Island('gc', '', 'Gran Canaria', key: 'gc', position: 2),
        Island('tf', '', 'Tenerife', key: 'TF', position: 1),
      ]);
      expect(list.map((i) => i.id), ['tf', 'gc']);
      expect(onbIslandBadge(list.last), 'GC');
    });

    test('sin key: iniciales o dos primeras letras', () {
      expect(onbIslandBadge(Island('x', '', 'Gran Canaria')), 'GC');
      expect(onbIslandBadge(Island('y', '', 'Tenerife')), 'TE');
    });

    test('botón: elige una isla, continuar o elegir más tarde', () {
      expect(onbIslandCta(loading: false, failed: false, selected: false),
          'Elige una isla');
      expect(onbIslandCta(loading: false, failed: false, selected: true),
          'Continuar');
      expect(onbIslandCta(loading: true, failed: false, selected: false),
          'Continuar');
      expect(onbIslandCta(loading: false, failed: true, selected: false),
          'Elegir más tarde');
    });
  });

  group('ubicación', () {
    test('concedido = no denegado tras pedir permiso', () {
      expect(onbLocationGranted(LocationLoading()), isTrue);
      expect(onbLocationGranted(LocationUnavailable()), isTrue);
      expect(onbLocationGranted(LocationDenied()), isFalse);
      expect(onbLocationGranted(LocationPermanentlyDenied()), isFalse);
      expect(onbLocationGranted(LocationServiceDisabled()), isFalse);
      expect(onbLocationGranted(LocationInitial()), isFalse);
    });

    test('textos del estado sin ubicación', () {
      expect(onbLocationTitle(declined: true), 'Sin ubicación, de momento');
      expect(onbLocationSubtitle(declined: true, islandName: 'Tenerife'),
          contains('lo mejor de Tenerife'));
      expect(onbLocationSubtitle(declined: true, islandName: null),
          contains('lo mejor de Canarias'));
    });
  });

  group('cuenta', () {
    Restaurant r(String id, double avg, {String foto = 'https://x/y.jpg'}) =>
        Restaurant(id: id, nombre: 'Sitio $id')
          ..mainFoto = foto
          ..avgRating = avg;

    test('dos sitios reales con foto, los mejor valorados', () {
      final picked = onbAccountPlaces(
          [r('a', 4.0), r('b', 4.9), r('c', 5.0, foto: ''), r('d', 4.5)]);
      expect(picked.map((x) => x.id), ['b', 'd']);
    });

    test('mensajes de conexión por proveedor', () {
      expect(onbAuthLoadingLabel(OnbAuthProvider.google),
          'Conectando con Google…');
      expect(onbAuthErrorTitle(OnbAuthProvider.apple),
          'No hemos podido conectar con Apple');
    });
  });
}
