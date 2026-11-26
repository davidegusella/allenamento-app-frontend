import 'package:allenamentofrontend/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Client verso un server finto che risponde con [gestore], senza usare la rete
ApiService apiFinta(MockClientHandler gestore) {
  return ApiService(client: MockClient(gestore), baseUrl: 'http://localhost/api');
}

/// Client REST: token, JSON, risposte vuote ed errori
void main() {
  test('Access token, JSON and 204 responses', () async {
    final api = apiFinta((richiesta) async {
      expect(richiesta.headers['Authorization'], 'Bearer test');
      expect(richiesta.method, 'DELETE');
      return http.Response('', 204);
    });
    api.token = 'test';

    expect(await api.request('DELETE', '/plans/1'), isNull);
    api.dispose();
  });

  test('Without a token no Authorization header is sent', () async {
    final api = apiFinta((richiesta) async {
      expect(richiesta.headers.containsKey('Authorization'), isFalse);
      return http.Response('{"token":"t","user":{"id":1,"username":"a","email":"a@b.it"}}', 200);
    });

    final json = await api.request('POST', '/auth/login', {'email': 'a@b.it', 'password': 'x'});
    expect(json['token'], 't');
    api.dispose();
  });

  test('Server conflict is surfaced without claiming success', () async {
    final api = apiFinta((richiesta) async {
      return http.Response('{"message":"Scheda modificata"}', 409);
    });

    await expectLater(
      api.request('PUT', '/plans/1', {'name': 'Forza'}),
      throwsA(isA<ApiFailure>().having((errore) => errore.status, 'status', 409)),
    );
    api.dispose();
  });

  test('Malformed server data is reported', () async {
    final api = apiFinta((richiesta) async {
      return http.Response('<html>error</html>', 200);
    });

    await expectLater(api.request('GET', '/plans'), throwsA(isA<ApiFailure>()));
    api.dispose();
  });
}
