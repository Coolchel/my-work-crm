import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiUrls {
  // Fallback URL for Android emulator.
  static const String _defaultAndroidBaseUrl = 'http://10.0.2.2:8000/api';

  // Fallback URL for desktop/web local development.
  static const String _defaultLocalBaseUrl = 'http://127.0.0.1:8000/api';

  // Shared URL for all platforms.
  static const String _apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  // Optional override just for web.
  static const String _apiBaseUrlWeb =
      String.fromEnvironment('API_BASE_URL_WEB', defaultValue: '');

  // Optional override just for Android.
  static const String _apiBaseUrlAndroid =
      String.fromEnvironment('API_BASE_URL_ANDROID', defaultValue: '');

  static String get baseUrl {
    if (kIsWeb) {
      if (_apiBaseUrlWeb.isNotEmpty) return _apiBaseUrlWeb;
      if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
      return _defaultLocalBaseUrl;
    }

    if (Platform.isAndroid) {
      if (_apiBaseUrlAndroid.isNotEmpty) return _apiBaseUrlAndroid;
      if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
      return _defaultAndroidBaseUrl;
    }

    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    return _defaultLocalBaseUrl;
  }
}
