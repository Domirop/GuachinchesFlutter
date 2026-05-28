import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/local/http_cache_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _categoriesJson =
    '[{"id":"cat-1","nombre":"Tradicional","iconUrl":"","foto":""}]';

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput: 'ENDPOINT_V2=https://fake.test/v2/\n'
          'ENDPOINT_V1=https://fake.test/v1/\n',
    );
  });

  late HttpCacheStore cache;
  late int callCount;
  late MockClient client;
  late HttpRemoteRepository repo;

  setUp(() {
    cache = HttpCacheStore.withStorage(InMemoryCacheStorage());
    callCount = 0;
    client = MockClient((request) async {
      callCount++;
      return http.Response(_categoriesJson, 200);
    });
    repo = HttpRemoteRepository(client, cache: cache, backgroundEnabled: false);
  });

  test('(a) primera llamada hace network y escribe cache', () async {
    final result = await repo.getAllCategories();

    expect(callCount, 1);
    expect(result, isNotEmpty);
    expect(result.first.id, 'cat-1');
    // verify the response body was persisted
    final cached = await cache.readStale('categories');
    expect(cached, isNotNull);
  });

  test('(b) segunda llamada inmediata devuelve cache y NO hace network', () async {
    await repo.getAllCategories(); // call 1 — network
    expect(callCount, 1);

    final result = await repo.getAllCategories(); // call 2 — from cache
    expect(callCount, 1); // main path did not hit network
    expect(result.first.id, 'cat-1');
  });

  test('(c) tras invalidateCache, tercera llamada vuelve a hacer network', () async {
    await repo.getAllCategories(); // call 1 — network
    await repo.getAllCategories(); // call 2 — cache (count stays 1)

    await repo.invalidateCache('categories');

    await repo.getAllCategories(); // call 3 — cache invalidated, back to network
    expect(callCount, 2); // call 1 + call 3
  });
}
