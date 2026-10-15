import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/User.dart';
import 'package:guachinches/ui/pages/restaurant_detail/reviews_logic.dart';

Review _r(String id, String rating,
        {String title = '', String text = '', String userId = ''}) =>
    Review(
      id: id,
      rating: rating,
      title: title,
      review: text,
      usuario: User(id: userId, nombre: 'Ana López'),
    );

void main() {
  group('textos de relleno', () {
    test('«Título» y «Sin título» no se pintan', () {
      expect(reviewDisplayTitle('Título'), '');
      expect(reviewDisplayTitle(' titulo '), '');
      expect(reviewDisplayTitle('Sin título.'), '');
      expect(reviewDisplayTitle('Un 10!!!'), 'Un 10!!!');
    });

    test('«Sin descripción» no se pinta; el resto, literal', () {
      expect(reviewDisplayText('Sin descripción'), '');
      expect(reviewDisplayText('sin descripcion.'), '');
      expect(
          reviewDisplayText('  las papas,9e buenas '), 'las papas,9e buenas');
    });

    test('reviewHasComment', () {
      expect(reviewHasComment(_r('1', '5', title: 'Título')), isFalse);
      expect(reviewHasComment(_r('1', '5', text: 'Rico')), isTrue);
    });
  });

  group('orden', () {
    final list = [
      _r('a', '3'),
      _r('b', '5', text: 'Muy rico'),
      _r('c', '1', title: 'Flojo'),
      _r('d', '5'),
    ];

    test('Relevantes: con comentario primero, sin tocar el orden', () {
      expect(reviewsSorted(list, ReviewSort.relevant).map((r) => r.id),
          ['b', 'c', 'a', 'd']);
    });

    test('Mejor puntuadas: por estrellas, comentario antes a igualdad', () {
      expect(reviewsSorted(list, ReviewSort.best).map((r) => r.id),
          ['b', 'd', 'a', 'c']);
    });

    test('Peor puntuadas', () {
      expect(reviewsSorted(list, ReviewSort.worst).map((r) => r.id),
          ['c', 'a', 'b', 'd']);
    });
  });

  test('fuera las reseñas de personas bloqueadas', () {
    final list = [
      _r('1', '5', userId: 'u1'),
      _r('2', '4', userId: 'u2'),
    ];
    expect(reviewsWithoutBlocked(list, {'u1'}).map((r) => r.id), ['2']);
  });

  test('autor: nombre de pila', () {
    expect(reviewAuthorName(_r('1', '5')), 'Ana');
  });

  test('motivos con código estable', () {
    expect(ReviewReportReason.values.map((r) => r.code),
        ['spam', 'offensive', 'personal_data', 'off_topic', 'other']);
    expect(
        ReviewReportReason.personalData.label, 'Datos personales de alguien');
  });

  test('antetítulo y recuento', () {
    expect(reviewsEyebrow('Guachinche El Fogón', 'La Laguna'),
        'Guachinche El Fogón · La Laguna');
    expect(reviewsEyebrow('El Fogón', ''), 'El Fogón');
    expect(reviewsCountLabel(1), '1 reseña');
    expect(reviewsCountLabel(36), '36 reseñas');
  });

  test('correo a soporte', () {
    final uri = reviewSupportMailUri(
        restaurantName: 'El Fogón', authorName: 'Laura', reviewId: 'r9');
    expect(uri.scheme, 'mailto');
    expect(uri.toString(), contains('r9'));
  });
}
