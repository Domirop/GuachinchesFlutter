import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/ui/pages/advance_search/map_clusters.dart';

void main() {
  // La Laguna, a ~300 m entre sí; Adeje, lejos.
  const pts = [
    (28.4874, -16.3159),
    (28.4880, -16.3130),
    (28.0910, -16.7280),
  ];

  test('a zoom de isla se juntan los cercanos; los lejanos van solos', () {
    final c = mapClusters(pts, 10);
    expect(c.length, 2);
    expect(c.first.members, [0, 1]);
    expect(c.last.single, isTrue);
  });

  test('acercando el mapa se separan', () {
    final c = mapClusters(pts, 17);
    expect(c.length, 3);
    expect(c.every((x) => x.single), isTrue);
  });
}
