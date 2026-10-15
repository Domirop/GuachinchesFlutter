import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/pages/settings/perfil_logic.dart';

void main() {
  group('proveedor', () {
    test('lee los tres proveedores y descarta lo desconocido', () {
      expect(perfilProviderFrom('google'), PerfilProvider.google);
      expect(perfilProviderFrom(' Apple '), PerfilProvider.apple);
      expect(perfilProviderFrom('email'), PerfilProvider.email);
      expect(perfilProviderFrom('facebook'), isNull);
      expect(perfilProviderFrom(null), isNull);
    });

    test('línea «Has entrado con…»', () {
      expect(
          perfilProviderLine(PerfilProvider.google), 'Has entrado con Google');
      expect(perfilProviderLine(PerfilProvider.apple), 'Has entrado con Apple');
      expect(perfilProviderLine(PerfilProvider.email), 'Has entrado con email');
    });
  });

  group('identidad', () {
    test('el nombre del backend manda; si viene vacío, el guardado', () {
      expect(perfilDisplayName('Carmen', 'Otra'), 'Carmen');
      expect(perfilDisplayName('  ', 'Carmen'), 'Carmen');
      expect(perfilDisplayName('', null), '');
    });

    test('inicial del nombre, si no del email, si no vacía', () {
      expect(perfilInitial('carmen', 'x@y.com'), 'C');
      expect(perfilInitial('', 'pepe@y.com'), 'P');
      expect(perfilInitial(' ', null), '');
    });
  });

  group('resumen de actividad', () {
    test('estrellas válidas', () {
      expect(perfilStars('4'), 4);
      expect(perfilStars('4.6'), 5);
      expect(perfilStars('9'), 5);
      expect(perfilStars('0'), isNull);
      expect(perfilStars('abc'), isNull);
    });

    test('media ignorando notas no válidas', () {
      expect(perfilAverage(['4', '5', '', 'x']), 4.5);
      expect(perfilAverage(const []), isNull);
      expect(perfilFormatAvg(4.5), '4,5');
      expect(perfilFormatAvg(4), '4,0');
    });

    test('subtítulo de Mis reseñas', () {
      expect(perfilReviewsSummary(4, 4.5), '4 reseñas · media 4,5');
      expect(perfilReviewsSummary(1, 4), '1 reseña · media 4,0');
      expect(perfilReviewsSummary(2, null), '2 reseñas');
      expect(perfilReviewsSummary(0, null), 'Aún no has escrito ninguna');
    });

    test('subtítulo de Guardados', () {
      expect(perfilSavedSummary(5), '5 sitios en este móvil');
      expect(perfilSavedSummary(1), '1 sitio en este móvil');
      expect(perfilSavedSummary(0), 'Aún no has guardado ningún sitio');
    });
  });

  test('versión del pie sin número de compilación y con respaldo', () {
    expect(perfilVersionLabel('4.7.1+99'), 'Dónde Comer Canarias 4.7.1');
    // Sin versión leída no se inventa ninguna.
    expect(perfilVersionLabel(null), 'Dónde Comer Canarias');
    expect(perfilVersionLabel(' '), 'Dónde Comer Canarias');
  });

  group('eliminación de cuenta', () {
    final at = DateTime(2026, 11, 13, 10);
    final now = DateTime(2026, 10, 14, 9, 41);

    test('fechas corta y larga', () {
      expect(perfilDateShort(at), '13/11/2026');
      expect(perfilDateLong(at), '13 de noviembre');
      expect(perfilDateLong(at, withYear: true), '13 de noviembre de 2026');
      expect(perfilDateShort(perfilDeletionRequestedAt(at)), '14/10/2026');
    });

    test('pendiente solo si la fecha es futura', () {
      expect(perfilDeletionActive(at, now), isTrue);
      expect(perfilDeletionActive(at, DateTime(2026, 12, 1)), isFalse);
      expect(perfilDeletionActive(null, now), isFalse);
    });

    test('días que quedan', () {
      expect(perfilDaysLeft(at, now), 30);
      expect(perfilDaysLeftText(30), 'Quedan 30 días.');
      expect(perfilDaysLeftText(1), 'Queda 1 día.');
      expect(perfilDaysLeftText(0), 'Se elimina hoy.');
      expect(perfilDaysLeft(at, DateTime(2026, 12, 1)), 0);
    });
  });

  test('cerrar sesión: Apple solo en iOS', () {
    expect(perfilLogoutText(apple: true), contains('Apple, Google o tu email'));
    expect(perfilLogoutText(apple: false),
        contains('entra con Google o tu email'));
  });
}
