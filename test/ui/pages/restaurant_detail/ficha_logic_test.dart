import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/CategoryRestaurant.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/short_quote.dart';
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/write_review_screen.dart';

Visit _visit(String id, String date,
        {double? price,
        List<String> services = const [],
        List<String> pros = const [],
        List<String> cons = const [],
        List<VisitQuote> quotes = const []}) =>
    Visit(
      id: id,
      restaurantId: 'r',
      videoPublishedAt: date,
      priceApprox: price,
      services: services,
      highlights: pros,
      lowlights: cons,
      quotes: quotes,
    );

CategoryRestaurant _cat(String name) => CategoryRestaurant(
      id: name,
      categoriasRestauranteId: 'r',
      categoriaId: name,
      categorias: ModelCategory(id: name, nombre: name, iconUrl: '', foto: ''),
    );

void main() {
  group('Visitas', () {
    test('la más reciente por fecha real del vídeo, no por el orden del backend',
        () {
      final v = [
        _visit('vieja', '2024-01-10T00:00:00Z'),
        _visit('nueva', '2026-10-08T00:00:00Z'),
        _visit('media', '2025-05-01T00:00:00Z'),
      ];
      expect(fichaLatestVisit(v)!.id, 'nueva');
      expect(fichaSortedVisits(v).map((e) => e.id), ['nueva', 'media', 'vieja']);
    });
  });

  group('Precio', () {
    test('de la visita más reciente con precio', () {
      final r = Restaurant(id: 'r');
      final v = [
        _visit('a', '2024-01-01T00:00:00Z', price: 20),
        _visit('b', '2026-01-01T00:00:00Z', price: 36.4),
      ];
      expect(fichaPriceLabel(r, v), '≈ 36 € por persona');
    });

    test('si no hay visita con precio, el rango del local; si no, nada', () {
      final r = Restaurant(id: 'r')
        ..minPrice = 15
        ..maxPrice = 25;
      expect(fichaPriceLabel(r, const []), '15–25 € por persona');
      expect(fichaPriceLabel(Restaurant(id: 'x'), const []), isNull);
    });
  });

  group('Características', () {
    test('servicios mapeados y sin duplicar con las categorías', () {
      final r = Restaurant(
          id: 'r', categoriaRestaurantes: [_cat('Terraza'), _cat('carne cabra')]);
      final v = [
        _visit('a', '2026-01-01T00:00:00Z', services: [
          'terraza',
          'aparcamiento',
          'acceso_pmr',
          'petfriendly',
          'datafono',
          'reservas',
        ]),
      ];
      expect(fichaFeatures(r, v).map((f) => f.label), [
        'Terraza',
        'Carne de cabra',
        'Aparcamiento',
        'Accesible',
        'Admite mascotas',
        'Datáfono',
      ]);
      expect(fichaTakesReservations(v), isTrue);
    });
  });

  group('Citas', () {
    test('literales, sin hablante y con comillas latinas', () {
      expect(fichaQuote('Joana: Son caseritos, mi niña.'),
          '«Son caseritos, mi niña.»');
      expect(fichaQuote('"Pídanselo porque están superricos."'),
          '«Pídanselo porque están superricos.»');
    });

    test('la del teaser no repite una del short y prefiere positivas', () {
      final v = _visit('a', '2026-01-01T00:00:00Z', quotes: const [
        VisitQuote(text: 'Esto es uno de los platos estrella.', sentiment: 'positive'),
        VisitQuote(text: 'La subida es empinada.', sentiment: 'negative'),
        VisitQuote(text: 'Pídanselo porque están superricos.', sentiment: 'positive'),
      ]);
      final short = [const ShortQuote(text: 'Pídanselo porque están superricos.')];
      expect(fichaTeaserQuote(v, short), '«Esto es uno de los platos estrella.»');
    });

    test('«Lo que dicen»: Ojo para avisos, sin hablante', () {
      final r = Restaurant(id: 'r')
        ..shortQuotes = const [
          ShortQuote(text: 'Jonay: No nos parece caro.'),
          ShortQuote(text: 'La pechada para subir.', isWarning: true),
        ];
      final s = fichaSayings(r, const []);
      expect(s.map((e) => e.text), ['«No nos parece caro.»', '«La pechada para subir.»']);
      expect(s.map((e) => e.warning), [false, true]);
    });
  });

  group('Resumen con IA', () {
    test('junta a favor / en contra de todas las visitas sin duplicados', () {
      final v = [
        _visit('a', '2026-01-01T00:00:00Z',
            pros: ['Comida casera', 'Buen precio'], cons: ['Subida empinada']),
        _visit('b', '2025-01-01T00:00:00Z',
            pros: ['comida casera.', 'Terraza'], cons: ['Subida  empinada']),
      ];
      final s = fichaAiSummary(v);
      expect(s.pros, ['Comida casera', 'Buen precio', 'Terraza']);
      expect(s.cons, ['Subida empinada']);
      expect(s.visitCount, 2);
    });
  });

  group('Reseñas', () {
    test('«Ver todas» solo con más de 3', () {
      expect(fichaShowAllReviews(3), isFalse);
      expect(fichaShowAllReviews(4), isTrue);
    });

    test('el Nº en la isla solo con 10 reseñas o más', () {
      Restaurant withReviews(int n) => Restaurant(
          id: 'r', valoraciones: List.generate(n, (i) => Review(id: '$i')))
        ..rankNumber = 2;
      expect(fichaShowRank(withReviews(3)), isFalse);
      expect(fichaShowRank(withReviews(10)), isTrue);
      expect(fichaShowRank(withReviews(12)..rankNumber = null), isFalse);
    });

    test('nombre de pila y sin relleno «Sin descripción»', () {
      expect(fichaFirstName('pedro García'), 'Pedro');
      expect(fichaFirstName(null), 'Anónimo');
      expect(fichaReviewText('Sin descripción'), '');
      expect(fichaReviewText(' rica '), 'rica');
    });

    test('validación de la reseña: nota obligatoria y 0 u 8+ caracteres', () {
      expect(WriteReviewScreen.canSubmit(0, ''), isFalse);
      expect(WriteReviewScreen.canSubmit(4, ''), isTrue);
      expect(WriteReviewScreen.canSubmit(4, 'corto'), isFalse);
      expect(WriteReviewScreen.canSubmit(4, 'bastante largo'), isTrue);
    });
  });

  group('Dirección', () {
    test('quita el emoji inicial y separa el código postal', () {
      const raw =
          '📍Calle Pedro Hernández, 84, 38389 La Victoria de Acentejo, Santa Cruz de Tenerife';
      expect(fichaCleanAddress(raw).startsWith('Calle'), isTrue);
      expect(fichaAddressLines(raw),
          'Calle Pedro Hernández, 84\n38389 La Victoria de Acentejo');
    });

    test('Instagram desde enlace o usuario', () {
      expect(fichaInstagramHandle('https://www.instagram.com/casaangela/'),
          '@casaangela');
      expect(fichaInstagramHandle('@@casa.angela'), '@casa.angela');
    });
  });

  group('Horario', () {
    // Martes cerrado; miércoles 12:00–22:00; domingo 12:00–17:00.
    final json = {
      'periods': [
        {'open': {'day': 3, 'time': '1200'}, 'close': {'day': 3, 'time': '2200'}},
        {'open': {'day': 0, 'time': '1200'}, 'close': {'day': 0, 'time': '1700'}},
      ],
      'weekday_text': [
        'lunes: Cerrado',
        'martes: Cerrado',
        'miércoles: 12:00–22:00',
        'jueves: Cerrado',
        'viernes: Cerrado',
        'sábado: Cerrado',
        'domingo: 12:00–17:00',
      ],
    };
    final r = Restaurant(id: 'r')..horariosJson = json;

    test('abierto: hasta la hora de cierre', () {
      final s = fichaStatus(r, DateTime(2026, 10, 11, 13)); // domingo
      expect(s!.open, isTrue);
      expect(s.rest, 'hasta las 17:00');
    });

    test('cerrado: próxima apertura con día', () {
      final s = fichaStatus(r, DateTime(2026, 10, 13, 10)); // martes
      expect(s!.open, isFalse);
      expect(s.rest, 'abre mañana a las 12:00');
      final s2 = fichaStatus(r, DateTime(2026, 10, 12, 10)); // lunes
      expect(s2!.rest, 'abre el miércoles a las 12:00');
    });

    test('semana de lunes a domingo con hoy marcado', () {
      final w = fichaWeek(r, DateTime(2026, 10, 11, 13))!;
      expect(w.today, 6);
      expect(w.hours[2], '12:00–22:00');
      expect(w.hours[0], 'Cerrado');
    });
  });

  group('Listas', () {
    test('puesto 1-based aunque el backend numere desde 0', () {
      expect(fichaListRank([('a', 0), ('b', 1), ('c', 2)], 'a'), 1);
      expect(fichaListRank([('a', 1), ('b', 2)], 'b'), 2);
      expect(fichaListRank([('a', 1)], 'z'), isNull);
    });

    test('rutas con parada; tops con puesto (sin ceros)', () {
      expect(fichaListLabel('RUTA', 2, 12), 'Ruta · Parada 2 de 12');
      expect(fichaListLabel('TOP', 1, 7), 'Top · Puesto nº 1');
    });
  });
}
