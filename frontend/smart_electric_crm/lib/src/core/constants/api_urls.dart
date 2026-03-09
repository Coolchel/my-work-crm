import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiUrls {
  // Fallback URL for Android emulator.
  static const String _defaultAndroidBaseUrl = 'http://10.0.2.2:8000/api';

  // Fallback URL for desktop/web local development.
  static const String _defaultLocalBaseUrl = 'http://127.0.0.1:8000/api';

  // Default backend port for web local development when Flutter dev server
  // runs on another port of the same machine.
  static const int _defaultWebDevBackendPort =
      int.fromEnvironment('API_WEB_BACKEND_PORT', defaultValue: 8000);

  // Shared URL for all platforms.
  static const String _apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  // Optional override just for web.
  static const String _apiBaseUrlWeb =
      String.fromEnvironment('API_BASE_URL_WEB', defaultValue: '');

  // Optional override just for Android.
  static const String _apiBaseUrlAndroid =
      String.fromEnvironment('API_BASE_URL_ANDROID', defaultValue: '');

  static String get baseUrl => resolveBaseUrl(
        isWeb: kIsWeb,
        isAndroid: !kIsWeb && Platform.isAndroid,
        currentUri: kIsWeb ? Uri.base : null,
        apiBaseUrl: _apiBaseUrl,
        apiBaseUrlWeb: _apiBaseUrlWeb,
        apiBaseUrlAndroid: _apiBaseUrlAndroid,
        webDevBackendPort: _defaultWebDevBackendPort,
      );

  static String resolveBaseUrl({
    required bool isWeb,
    required bool isAndroid,
    Uri? currentUri,
    String apiBaseUrl = '',
    String apiBaseUrlWeb = '',
    String apiBaseUrlAndroid = '',
    int webDevBackendPort = _defaultWebDevBackendPort,
  }) {
    if (isWeb) {
      final webOverride = _normalizeBaseUrl(apiBaseUrlWeb);
      if (webOverride.isNotEmpty) {
        return webOverride;
      }

      final sharedOverride = _normalizeBaseUrl(apiBaseUrl);
      if (sharedOverride.isNotEmpty) {
        return sharedOverride;
      }

      return _resolveDefaultWebBaseUrl(
        currentUri: currentUri ?? Uri.base,
        webDevBackendPort: webDevBackendPort,
      );
    }

    if (isAndroid) {
      final androidOverride = _normalizeBaseUrl(apiBaseUrlAndroid);
      if (androidOverride.isNotEmpty) {
        return androidOverride;
      }

      final sharedOverride = _normalizeBaseUrl(apiBaseUrl);
      if (sharedOverride.isNotEmpty) {
        return sharedOverride;
      }

      return _defaultAndroidBaseUrl;
    }

    final sharedOverride = _normalizeBaseUrl(apiBaseUrl);
    if (sharedOverride.isNotEmpty) {
      return sharedOverride;
    }

    return _defaultLocalBaseUrl;
  }

  static String resolveBackendUrl(
    String urlOrPath, {
    String? baseUrl,
    Uri? currentUri,
  }) {
    final trimmed = urlOrPath.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) {
      return trimmed;
    }

    if (parsed.hasScheme) {
      return parsed.toString();
    }

    return _resolveBackendRootUri(
      baseUrl: baseUrl ?? ApiUrls.baseUrl,
      currentUri: currentUri ?? (kIsWeb ? Uri.base : null),
    ).resolve(_trimLeadingSlash(trimmed)).toString();
  }

  static String _resolveDefaultWebBaseUrl({
    required Uri currentUri,
    required int webDevBackendPort,
  }) {
    if (currentUri.host.isEmpty) {
      return '/api';
    }

    if (_shouldUseDedicatedWebDevBackendPort(currentUri.host)) {
      return Uri(
        scheme: currentUri.scheme.isEmpty ? 'http' : currentUri.scheme,
        host: currentUri.host,
        port: webDevBackendPort,
        path: '/api',
      ).toString();
    }

    return '/api';
  }

  static Uri _resolveBackendRootUri({
    required String baseUrl,
    Uri? currentUri,
  }) {
    final apiBaseUri = Uri.tryParse(baseUrl);
    if (apiBaseUri != null && apiBaseUri.hasScheme) {
      return apiBaseUri.replace(path: '/', query: null, fragment: null);
    }

    if (currentUri != null) {
      return currentUri.resolve('/');
    }

    return Uri.parse(_defaultLocalBaseUrl).resolve('/');
  }

  static String _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    return trimmed.replaceFirst(RegExp(r'/+$'), '');
  }

  static String _trimLeadingSlash(String value) {
    return value.replaceFirst(RegExp(r'^/+'), '');
  }

  static bool _shouldUseDedicatedWebDevBackendPort(String host) {
    final normalizedHost = host.trim().toLowerCase();
    if (normalizedHost.isEmpty) {
      return false;
    }

    if (_isLoopbackHost(normalizedHost)) {
      return true;
    }

    return _isPrivateIpv4Host(normalizedHost);
  }

  static bool _isLoopbackHost(String host) {
    final normalized = host.replaceAll('[', '').replaceAll(']', '');
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1';
  }

  static bool _isPrivateIpv4Host(String host) {
    final segments = host.split('.');
    if (segments.length != 4) {
      return false;
    }

    final octets = <int>[];
    for (final segment in segments) {
      final value = int.tryParse(segment);
      if (value == null || value < 0 || value > 255) {
        return false;
      }
      octets.add(value);
    }

    if (octets[0] == 10) {
      return true;
    }

    if (octets[0] == 192 && octets[1] == 168) {
      return true;
    }

    return octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31;
  }
}
