import 'package:chanolite/models/mod_model.dart';
import 'package:chanolite/services/mod_service.dart';
import 'package:chanolite/services/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Real production response shape (Mod id 6, truncated) so parsing is pinned
/// to the wire contract, not to our imagination of it.
const _realEnvelope = '''
{
  "data": {
    "mods": [
      {
        "id": 6,
        "articleId": 852,
        "creatorId": 429,
        "name": "RPGM Translation (Thai)",
        "description": "Thai translation",
        "creditTo": "Lingo Translator",
        "version": "1.0",
        "downloadLink": "https://storage.chanomhub.com/x/chanomhub_patch_1793733874030.patch.json.gz",
        "status": "APPROVED",
        "type": "TRANSLATION",
        "language": "Thai"
      }
    ],
    "modsCount": 1
  }
}
''';

void main() {
  test('parses the real GET /mods/article/:slug envelope', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(),
          contains('/api/mods/article/nokos-lucky-rock-paper-scissors-HJ1045'));
      return http.Response(_realEnvelope, 200);
    });
    final service = ModService(apiClient: ApiClient(httpClient: client));
    // Simulate the auth token being unset for guests.
    ApiClient.updateAuthToken(null);

    final mods = await service.getModsForArticle(
        'nokos-lucky-rock-paper-scissors-HJ1045');

    expect(mods, hasLength(1));
    expect(mods.first.id, 6);
    expect(mods.first.name, 'RPGM Translation (Thai)');
    expect(mods.first.downloadLink, endsWith('.patch.json.gz'));
  });

  test('GameMod.fromJson tolerates a sparse response', () {
    final mod = GameMod.fromJson({'id': 7});
    expect(mod.id, 7);
    expect(mod.name, isNull);
    expect(mod.downloadLink, isNull);
  });
}
