import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/local/http_cache_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

HttpRemoteRepository _repo(int status, String body, {List<http.Request>? log}) =>
    HttpRemoteRepository(
      MockClient((req) async {
        log?.add(req);
        return http.Response(body, status);
      }),
      cache: HttpCacheStore.withStorage(InMemoryCacheStorage()),
      backgroundEnabled: false,
    );

Future<bool> _update(HttpRemoteRepository r) =>
    r.updateReview('u1', 'rev1', 'Título', '4', 'Texto de la reseña');

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput: 'ENDPOINT_V2=https://fake.test/v2/\n'
          'ENDPOINT_V1=https://fake.test/v1/\n',
    );
  });

  test('2xx con code 200 → éxito (PUT a user/:id/review/:id)', () async {
    final log = <http.Request>[];
    expect(await _update(_repo(200, '{"code":200}', log: log)), isTrue);
    expect(log.single.method, 'PUT');
    expect(log.single.url.toString(), 'https://fake.test/v1/user/u1/review/rev1');
  });

  test('2xx con JSON sin code → éxito', () async {
    expect(await _update(_repo(200, '{"id":"rev1"}')), isTrue);
  });

  test('404 → fallo', () async {
    expect(await _update(_repo(404, '{"code":404}')), isFalse);
  });

  test('200 con code distinto de 200 → fallo', () async {
    expect(await _update(_repo(200, '{"code":500}')), isFalse);
  });

  test('cuerpo no JSON → fallo', () async {
    expect(await _update(_repo(200, '<html>Cannot PUT</html>')), isFalse);
  });
}
