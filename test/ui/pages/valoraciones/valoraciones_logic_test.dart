import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/ui/pages/valoraciones/valoraciones_logic.dart';

void main() {
  test('palabra de la nota', () {
    expect(resenaWord(4), 'Muy buena');
    expect(resenaWord(5), 'Excelente');
    expect(resenaWord(null), '');
    expect(resenaWord(7), '');
  });

  test('acción: añadir texto si solo hay estrellas o título', () {
    expect(resenaActionLabel(Valoraciones(rating: '5')), 'Añadir texto');
    expect(resenaActionLabel(Valoraciones(rating: '5', title: 'Rico')),
        'Añadir texto');
    expect(resenaActionLabel(Valoraciones(rating: '4', review: 'Muy bueno')),
        'Editar');
  });

  test('solo estrellas', () {
    expect(resenaOnlyStars(Valoraciones(rating: '5')), isTrue);
    expect(resenaOnlyStars(Valoraciones(rating: '5', title: 'x')), isFalse);
  });

  test('id del sitio: el del payload o el del restaurante incluido', () {
    expect(resenaRestaurantId(Valoraciones(valoracionesNegocioId: 'r1')), 'r1');
    expect(
        resenaRestaurantId(
            Valoraciones(restaurantes: Restaurantes(id: 'r2', nombre: 'X'))),
        'r2');
    expect(resenaRestaurantId(Valoraciones()), '');
  });

  test('pie del contador', () {
    expect(resenasCountCaption(1), 'reseña escrita');
    expect(resenasCountCaption(4), 'reseñas escritas');
  });
}
