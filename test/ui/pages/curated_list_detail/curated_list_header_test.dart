import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/pages/curated_list_detail/widgets/curated_list_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const scaler = TextScaler.noScaling;

  test('si cada palabra cabe a 34, se queda a 34', () {
    // «Top bar» = 3 letras por palabra → 102 px a 34.
    expect(CuratedListHeader.titleSizeBeside('Top bar', 194, scaler), 34);
  });

  test('baja de tamaño para que la palabra más larga quepa entera', () {
    // «Bocadillo» = 9 letras: 306 a 34, 279 a 31, 252 a 28 → cabe a 28.
    expect(CuratedListHeader.titleSizeBeside('Bocadillo', 260, scaler), 28);
  });

  test('si ni a 28 cabe, el título va a todo el ancho', () {
    expect(
        CuratedListHeader.titleSizeBeside('Japoneses en Tenerife', 194, scaler),
        isNull);
  });

  test('más de 3 líneas junto a la viñeta tampoco vale', () {
    expect(CuratedListHeader.titleSizeBeside('a b c d e f g h', 40, scaler),
        isNull);
  });
}
