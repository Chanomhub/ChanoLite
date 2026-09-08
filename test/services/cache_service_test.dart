import 'package:chanolite/services/cache_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CacheService Tests', () {
    late CacheService cacheService;

    setUp(() {
      cacheService = CacheService(maxEntries: 3);
    });

    test('get and set work properly', () {
      cacheService.set('key1', 'value1');
      expect(cacheService.get('key1'), 'value1');
    });

    test('returns null for non-existent key', () {
      expect(cacheService.get('missing'), isNull);
    });

    test('remove deletes the specified key', () {
      cacheService.set('key1', 'value1');
      cacheService.remove('key1');
      expect(cacheService.get('key1'), isNull);
    });

    test('clear wipes all keys', () {
      cacheService.set('k1', 'v1');
      cacheService.set('k2', 'v2');
      cacheService.clear();
      expect(cacheService.get('k1'), isNull);
      expect(cacheService.get('k2'), isNull);
    });

    test('evicts oldest when exceeding maxEntries', () {
      cacheService.set('k1', 'v1');
      cacheService.set('k2', 'v2');
      cacheService.set('k3', 'v3');
      cacheService.set('k4', 'v4'); // triggers eviction

      expect(cacheService.get('k1'), isNull); // Oldest removed
      expect(cacheService.get('k2'), 'v2');
      expect(cacheService.get('k3'), 'v3');
      expect(cacheService.get('k4'), 'v4');
    });

    test('expired entry returns null and gets removed', () async {
      cacheService.set('temp', 'temporary', duration: const Duration(milliseconds: 10));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(cacheService.get('temp'), isNull);
    });
  });
}
