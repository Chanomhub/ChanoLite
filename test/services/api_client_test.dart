import 'dart:convert';

import 'package:chanolite/services/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, int status) => http.Response(
      json.encode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  // Keep the static token state isolated per test.
  void clearAuth() {
    ApiClient.updateAuthToken(null);
    ApiClient.updateRefreshToken(null);
    ApiClient.onUnauthorized = null;
  }

  group('ApiClient transport', () {
    setUp(clearAuth);
    tearDown(clearAuth);

    test('sends Bearer header when a token is set', () async {
      ApiClient.updateAuthToken('tok-123');
      Uri? captured;
      final client = MockClient((req) async {
        captured = req.url;
        expect(req.headers['Authorization'], 'Bearer tok-123');
        return _json({'ok': true}, 200);
      });
      final api = ApiClient(httpClient: client);

      await api.get('engines');

      expect(captured.toString(), 'https://api.chanomhub.com/api/engines');
    });

    test('parses JSON body and returns decoded object', () async {
      final api = ApiClient(
        httpClient: MockClient(
          (req) async => _json({'data': {'v': 1}}, 200),
        ),
      );

      final result = await api.get('engines');

      expect(result, {'data': {'v': 1}});
    });

    test('returns empty map for empty 2xx body (204-style)', () async {
      final api = ApiClient(
        httpClient: MockClient((req) async => http.Response('', 204)),
      );

      expect(await api.delete('notifications/queue'), <String, dynamic>{});
    });

    test('throws on 500 with status in message', () async {
      final api = ApiClient(
        httpClient: MockClient((req) async => _json('boom', 500)),
      );

      await expectLater(api.get('engines'), throwsException);
    });

    test('401 triggers onUnauthorized then retries the request', () async {
      ApiClient.onUnauthorized = () async {};
      var calls = 0;
      final api = ApiClient(
        httpClient: MockClient((req) async {
          calls++;
          return calls == 1 ? _json('expired', 401) : _json({'ok': true}, 200);
        }),
      );

      final result = await api.get('me');

      expect(calls, 2);
      expect(result, {'ok': true});
    });

    test('401 without handler throws', () async {
      final api = ApiClient(
        httpClient: MockClient((req) async => _json('expired', 401)),
      );

      await expectLater(api.get('me'), throwsException);
    });
  });
}
