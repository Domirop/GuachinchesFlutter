import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/filter_session_cache.dart';
import 'package:guachinches/data/model/restaurant.dart';

void main() {
  test('guarda la isla sin filtrar, caduca a los 10 min y se vacía', () {
    var now = DateTime(2026, 10, 12, 12);
    final cache = FilterSessionCache(clock: () => now);
    final k = FilterSessionCache.key(
        island: 'tf', types: '', categories: '', municipalities: '');
    expect(cache.get(k), isNull);
    cache.put(k, [Restaurant(id: 'a'), Restaurant(id: 'b')]);
    expect(cache.get(k)!.map((r) => r.id), ['a', 'b']);

    now = now.add(const Duration(minutes: 9));
    expect(cache.get(k), isNotNull);
    now = now.add(const Duration(minutes: 2));
    expect(cache.get(k), isNull, reason: 'TTL de 10 min');

    cache.put(k, [Restaurant(id: 'a')]);
    cache.clear();
    expect(cache.get(k), isNull);
  });

  test('la clave lleva la isla y los filtros; solo sin texto', () {
    final tf = FilterSessionCache.key(
        island: 'tf', types: '', categories: '', municipalities: '');
    final gc = FilterSessionCache.key(
        island: 'gc', types: '', categories: '', municipalities: '');
    expect(tf == gc, isFalse);
    expect(FilterSessionCache.cacheable(''), isTrue);
    expect(FilterSessionCache.cacheable('cabra'), isFalse);
  });
}
