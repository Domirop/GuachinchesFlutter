import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/local/http_cache_store.dart';

void main() {
  late HttpCacheStore cache;

  setUp(() {
    cache = HttpCacheStore.withStorage(InMemoryCacheStorage());
  });

  test('(a) write+read(maxAge:1h) devuelve el body', () async {
    await cache.write('test-key', 'test-body');
    final result = await cache.read('test-key', maxAge: const Duration(hours: 1));
    expect(result, 'test-body');
  });

  test('(b) write+read(maxAge:Duration.zero) devuelve null por expirado', () async {
    await cache.write('test-key', 'test-body');
    final result = await cache.read('test-key', maxAge: Duration.zero);
    expect(result, isNull);
  });

  test('(c) write+readStale devuelve el body sin importar edad', () async {
    await cache.write('test-key', 'test-body');
    // read with Duration.zero confirms it's expired
    expect(await cache.read('test-key', maxAge: Duration.zero), isNull);
    // readStale still returns the body regardless of age
    final stale = await cache.readStale('test-key');
    expect(stale, 'test-body');
  });

  test('(d) read sobre key inexistente devuelve null', () async {
    final result = await cache.read('nonexistent', maxAge: const Duration(hours: 1));
    expect(result, isNull);
  });

  test('(e) write dos veces sobre la misma key hace overwrite', () async {
    await cache.write('test-key', 'body-1');
    await cache.write('test-key', 'body-2');
    final result = await cache.readStale('test-key');
    expect(result, 'body-2');
  });

  test('(f) invalidate borra solo claves con el prefijo dado', () async {
    await cache.write('restaurants:all:island-1', 'body-restaurants');
    await cache.write('restaurants:detail:r1', 'body-detail');
    await cache.write('categories', 'body-cats');

    await cache.invalidate('restaurants:');

    expect(await cache.readStale('restaurants:all:island-1'), isNull);
    expect(await cache.readStale('restaurants:detail:r1'), isNull);
    expect(await cache.readStale('categories'), 'body-cats');
  });

  test('(g) clear() vacía la base', () async {
    await cache.write('key-1', 'body-1');
    await cache.write('key-2', 'body-2');

    await cache.clear();

    expect(await cache.readStale('key-1'), isNull);
    expect(await cache.readStale('key-2'), isNull);
  });
}
