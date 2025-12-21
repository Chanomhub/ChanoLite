import 'package:chanolite/utils/image_url_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chanolite/constants/app_config.dart';

void main() {
  group('ImageUrlHelper', () {
    test('resolve returns null for null input', () {
      expect(ImageUrlHelper.resolve(null), isNull);
    });

    test('resolve returns null for empty input', () {
      expect(ImageUrlHelper.resolve(''), isNull);
    });

    test('resolve returns full URL as-is (http)', () {
      const url = 'http://example.com/image.jpg';
      expect(ImageUrlHelper.resolve(url), equals(url));
    });

    test('resolve returns full URL as-is (https)', () {
      const url = 'https://example.com/image.jpg';
      expect(ImageUrlHelper.resolve(url), equals(url));
    });

    test('resolve prepends CDN base URL for relative path with slash', () {
      const path = '/image.jpg';
      expect(
        ImageUrlHelper.resolve(path), 
        equals('${AppConfig.cdnBaseUrl}$path')
      );
    });

    test('resolve prepends CDN base URL and adds slash for filename only', () {
      const filename = 'image.jpg';
      expect(
        ImageUrlHelper.resolve(filename), 
        equals('${AppConfig.cdnBaseUrl}/$filename')
      );
    });

    test('resolve handles already resolved CDN URLs correctly', () {
      const url = '${AppConfig.cdnBaseUrl}/image.jpg';
      expect(ImageUrlHelper.resolve(url), equals(url));
    });

    test('resolveAll handles mixed list correctly', () {
      final inputs = [
        null,
        'https://example.com/1.jpg',
        '/2.jpg',
        '3.jpg',
        '',
      ];
      final expected = [
        'https://example.com/1.jpg',
        '${AppConfig.cdnBaseUrl}/2.jpg',
        '${AppConfig.cdnBaseUrl}/3.jpg',
      ];
      expect(ImageUrlHelper.resolveAll(inputs), equals(expected));
    });

    test('getFirstValid returns first resolved URL', () {
      final inputs = [
        null,
        '',
        '3.jpg',
      ];
      expect(
        ImageUrlHelper.getFirstValid(inputs), 
        equals('${AppConfig.cdnBaseUrl}/3.jpg')
      );
    });
  });
}
