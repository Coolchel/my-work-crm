import 'package:flutter_test/flutter_test.dart';
import 'package:smart_electric_crm/src/core/constants/api_urls.dart';

void main() {
  group('ApiUrls.resolveBaseUrl', () {
    test('uses localhost backend port for local web dev', () {
      final baseUrl = ApiUrls.resolveBaseUrl(
        isWeb: true,
        isAndroid: false,
        currentUri: Uri.parse('http://localhost:3000/projects'),
      );

      expect(baseUrl, 'http://localhost:8000/api');
    });

    test('uses LAN backend port for web opened from phone browser', () {
      final baseUrl = ApiUrls.resolveBaseUrl(
        isWeb: true,
        isAndroid: false,
        currentUri: Uri.parse('http://192.168.0.196:3000/projects/42'),
      );

      expect(baseUrl, 'http://192.168.0.196:8000/api');
    });

    test('uses same-origin /api for hosted web by default', () {
      final baseUrl = ApiUrls.resolveBaseUrl(
        isWeb: true,
        isAndroid: false,
        currentUri: Uri.parse('https://crm.example.com/projects'),
      );

      expect(baseUrl, '/api');
    });

    test('keeps explicit web override and normalizes trailing slash', () {
      final baseUrl = ApiUrls.resolveBaseUrl(
        isWeb: true,
        isAndroid: false,
        currentUri: Uri.parse('https://crm.example.com/projects'),
        apiBaseUrlWeb: '/api/',
      );

      expect(baseUrl, '/api');
    });
  });

  group('ApiUrls.resolveBackendUrl', () {
    test('keeps absolute file url unchanged', () {
      final resolved = ApiUrls.resolveBackendUrl(
        'https://crm.example.com/media/files/test.pdf',
        baseUrl: '/api',
        currentUri: Uri.parse('https://crm.example.com/projects'),
      );

      expect(resolved, 'https://crm.example.com/media/files/test.pdf');
    });

    test('resolves relative media url against backend host', () {
      final resolved = ApiUrls.resolveBackendUrl(
        '/media/files/test.pdf',
        baseUrl: 'http://192.168.0.196:8000/api',
      );

      expect(resolved, 'http://192.168.0.196:8000/media/files/test.pdf');
    });
  });
}
