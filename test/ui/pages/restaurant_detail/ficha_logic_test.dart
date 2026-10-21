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

    test('servicio «permite mascotas» no duplica la categoría', () {
      final r = Restaurant(id: 'r', categoriaRestaurantes: [_cat('Permite mascotas')]);
      final v = [
        _visit('a', '2026-01-01T00:00:00Z',
            services: ['permite_mascotas', 'comida para llevar']),
      ];
      expect(fichaFeatures(r, v).map((f) => f.label),
          ['Admite mascotas', 'Comida para llevar']);
    });
  });

  group('Citas', () {
    test('literales, sin hablante y con comillas latinas', () {
      expect(fichaQuote('Joana: Son caseritos, mi niña.'),
          '«Son caseritos, mi niña.»');
      expect(fichaQuote('"Pídanselo porque están superricos."'),
          '«Pídanselo porque están superricos.»');
    });

    test('mayúscula inicial y preferencia por frases completas', () {
      expect(fichaQuote('famoso bocadillo de cochino'),
          '«Famoso bocadillo de cochino»');
      expect(fichaQuote('¡qué rico!'), '«¡Qué rico!»');
      final v = _visit('a', '2026-01-01T00:00:00Z', quotes: const [
        VisitQuote(text: 'famoso bocadillo de cochino', sentiment: 'positive'),
        VisitQuote(text: 'Qué buenas están las arepas aquí.', sentiment: 'positive'),
      ]);
      expect(fichaTeaserQuote(v, const []), '«Qué buenas están las arepas aquí.»');
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

    test('«Lo que dicen en el vídeo»: citas curadas del short si la visita es el short',
        () {
      final r = Restaurant(id: 'r')
        ..shortVideoId = 'aUTCrn_SmEo'
        ..shortQuotes = const [
          ShortQuote(text: 'Jonay: No nos parece caro.'),
          ShortQuote(text: 'La pechada para subir.', isWarning: true),
        ];
      final v = Visit(
          id: 'a',
          restaurantId: 'r',
          thumbnail: 'https://i.ytimg.com/vi/aUTCrn_SmEo/hqdefault.jpg',
          quotes: const [VisitQuote(text: 'Otra frase.', sentiment: 'positive')]);
      final s = fichaVisitSayings(r, v);
      expect(s.map((e) => e.text), ['«No nos parece caro.»', '«La pechada para subir.»']);
      expect(s.map((e) => e.warning), [false, true]);
    });

    test('«Lo que dicen en el vídeo»: si no, las de la visita, Ojo en negativas y sin repetir',
        () {
      final r = Restaurant(id: 'r')..shortVideoId = 'otroShort11';
      final v = _visit('a', '2026-01-01T00:00:00Z', quotes: const [
        VisitQuote(text: 'Pídanselo porque están superricos.', sentiment: 'positive'),
        VisitQuote(text: 'La salsa está buenísima.', sentiment: 'positive'),
        VisitQuote(text: 'La pechada que tienes que subir.', sentiment: 'negative'),
        VisitQuote(text: 'la salsa está buenísima', sentiment: 'positive'),
        VisitQuote(text: 'En total pagamos 22 €.', sentiment: 'neutral'),
      ]);
      final s = fichaVisitSayings(r, v,
          exclude: ['«Pídanselo porque están superricos.»']);
      expect(s.map((e) => e.text), [
        '«La salsa está buenísima.»',
        '«La pechada que tienes que subir.»',
        '«En total pagamos 22 €.»',
      ]);
      expect(s.map((e) => e.warning), [false, true, false]);
      // Las neutras van sin marca (ni Positivo ni Ojo).
      expect(s.map((e) => e.neutral), [false, false, true]);
    });

    test('la cita de la portada reutiliza el criterio del teaser sin repetirla',
        () {
      final v = _visit('a', '2026-01-01T00:00:00Z', quotes: const [
        VisitQuote(text: 'Pídanselo.', sentiment: 'positive'),
        VisitQuote(text: 'La salsa está buenísima.', sentiment: 'positive'),
        VisitQuote(text: 'Es caro.', sentiment: 'negative'),
      ]);
      final teaser = fichaTeaserQuote(v, const []);
      expect(teaser, '«Pídanselo.»');
      expect(fichaReelQuote(v, exclude: [teaser!]), '«La salsa está buenísima.»');
      expect(fichaReelQuote(_visit('b', '2026-01-01T00:00:00Z')), isNull);
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

  group('Visitas tipo Reels', () {
    VisitDish dish(String name, {String? photo, String? sentiment}) =>
        VisitDish(name: name, photoUrl: photo, sentiment: sentiment);

    test('la más reciente primero (también para el carrusel)', () {
      final v = [
        _visit('6may2025', '2025-05-06T13:27:54Z'),
        _visit('10mar2026', '2026-03-10T12:58:49Z'),
      ];
      expect(fichaSortedVisits(v).map((e) => e.id), ['10mar2026', '6may2025']);
    });

    test('tamaños: la más reciente 160 × 284, las anteriores 132 × 234', () {
      expect(fichaReelSize(0), (width: 160.0, height: 284.0));
      expect(fichaReelSize(1), (width: 132.0, height: 234.0));
      expect(fichaReelSize(3), (width: 132.0, height: 234.0));
    });

    test('portada elegida: la del id si sigue; si no, la más reciente', () {
      final v = fichaSortedVisits([
        _visit('vieja', '2025-05-06T00:00:00Z'),
        _visit('nueva', '2026-03-10T00:00:00Z'),
      ]);
      expect(fichaSelectedVisit(v, null)!.id, 'nueva');
      expect(fichaSelectedVisit(v, 'vieja')!.id, 'vieja');
      expect(fichaSelectedVisit(v, 'borrada')!.id, 'nueva');
      expect(fichaSelectedVisit(const [], 'x'), isNull);
    });

    test('duración «m:ss» desde segundos o texto del backend', () {
      expect(fichaDuration(seconds: 95), '1:35');
      expect(fichaDuration(seconds: 58), '0:58');
      expect(fichaDuration(seconds: 130), '2:10');
      expect(fichaDuration(raw: 'PT1M12S'), '1:12');
      expect(fichaDuration(seconds: 0), isNull);
      expect(fichaVisitDuration(Visit(id: 'a', restaurantId: 'r', durationSeconds: 95)),
          '1:35');
      expect(fichaVisitDuration(Visit(id: 'a', restaurantId: 'r')), isNull);
    });

    test('pila de platos: 3 fotos y «+N» con el resto (los sin foto cuentan)', () {
      final six = Visit(id: 'a', restaurantId: 'r', dishes: [
        for (var i = 0; i < 5; i++) dish('Plato $i', photo: 'p$i.jpg'),
        dish('Quesillo'),
        dish('  '),
      ]);
      final s = fichaDishStack(six);
      expect(s.photos, ['p0.jpg', 'p1.jpg', 'p2.jpg']);
      expect(s.more, 3);

      final two = Visit(id: 'b', restaurantId: 'r', dishes: [
        dish('Bocadillo', photo: 'b.jpg'),
        dish('Arepas', photo: 'a.jpg'),
      ]);
      expect(fichaDishStack(two).photos.length, 2);
      expect(fichaDishStack(two).more, 0);

      // Sin fotos no hay pila ni «+N» suelto.
      final none = Visit(id: 'c', restaurantId: 'r', dishes: [dish('Arepas')]);
      expect(fichaDishStack(none).photos, isEmpty);
      expect(fichaDishStack(none).more, 0);
    });

    test('textos: chip de fecha, meta de la columna y antetítulo de platos', () {
      final v = Visit(
        id: 'a',
        restaurantId: 'r',
        videoPublishedAt: '2026-10-08T17:32:43Z',
        durationSeconds: 95,
        dishes: [
          for (var i = 0; i < 5; i++) dish('Plato $i', sentiment: 'loved'),
          dish('Quesillo', sentiment: 'liked'),
        ],
      );
      expect(fichaShortDateFromIso(v.sortDate), '8 oct');
      expect(fichaReelMeta(v), 'Short · 1:35 · 6 platos');
      expect(fichaOrderedEyebrow(v), 'Lo que pidieron el 8 oct · 5 les encantaron');
      expect(fichaVisitCount(1), '1 visita');
      expect(fichaVisitCount(2), '2 visitas');
    });

    test('miniaturas: vertical del Short, maxres, hq y la foto del local', () {
      final v = Visit(
          id: 'a',
          restaurantId: 'r',
          youtubeVideoId: '1e7e8252-6368-423b-93ed-acc752ca4cba',
          thumbnail: 'https://i.ytimg.com/vi/aUTCrn_SmEo/hqdefault.jpg');
      expect(fichaYoutubeId(v), 'aUTCrn_SmEo');
      expect(fichaReelThumbs(v, venuePhoto: 'local.jpg'), [
        'https://i.ytimg.com/vi/aUTCrn_SmEo/oardefault.jpg',
        'https://i.ytimg.com/vi/aUTCrn_SmEo/maxresdefault.jpg',
        'https://i.ytimg.com/vi/aUTCrn_SmEo/hqdefault.jpg',
        'local.jpg',
      ]);
      expect(fichaReelThumbs(Visit(id: 'b', restaurantId: 'r'), venuePhoto: 'l.jpg'),
          ['l.jpg']);
    });

    test('miniaturas: la portada de nuestro S3 va primero', () {
      final v = Visit.fromJson({
        'id': 'a',
        'restaurantId': 'r',
        'youtubeVideo': {
          'videoId': 'aUTCrn_SmEo',
          'posterUrl': 'https://louvre.s3.fr-par.scw.cloud/Guachinches/visit-posters/aUTCrn_SmEo.jpg?v=1',
        },
      });
      expect(v.posterUrl, endsWith('visit-posters/aUTCrn_SmEo.jpg?v=1'));
      expect(fichaReelThumbs(v).first, v.posterUrl);
      expect(fichaReelThumbs(v)[1],
          'https://i.ytimg.com/vi/aUTCrn_SmEo/oardefault.jpg');
    });
  });

  group('Short sin visitas', () {
    test('duración del short en segundos desde el texto del backend', () {
      expect(fichaDurationSeconds('PT1M35S'), 95);
      expect(fichaDurationSeconds('1:12'), 72);
      expect(fichaDurationSeconds('58'), 58);
      expect(fichaDurationSeconds(''), isNull);
      expect(fichaDurationSeconds('raro'), isNull);
    });

    test('el short como portada: id de YouTube, miniatura, duración y citas', () {
      final r = Restaurant(id: 'r')
        ..shortVideoId = 'aUTCrn_SmEo'
        ..shortDuration = 'PT1M35S'
        ..shortQuotes = const [
          ShortQuote(text: 'Pídanselo.'),
          ShortQuote(text: 'La pechada para subir.', isWarning: true),
        ];
      final v = fichaShortAsVisit(r)!;
      expect(fichaYoutubeId(v), 'aUTCrn_SmEo');
      expect(fichaVisitDuration(v), '1:35');
      expect(fichaReelThumbs(v).first,
          'https://i.ytimg.com/vi/aUTCrn_SmEo/oardefault.jpg');
      // «Lo que dicen en el vídeo» usa las citas curadas del short.
      final s = fichaVisitSayings(r, v);
      expect(s.map((e) => e.warning), [false, true]);
      expect(fichaShortAsVisit(Restaurant(id: 'x')), isNull);
    });
  });
}
