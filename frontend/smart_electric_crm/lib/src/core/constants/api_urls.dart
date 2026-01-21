import 'dart:io';
import 'package:flutter/foundation.dart'; // Для проверки kIsWeb

class ApiUrls {
  // Специальный IP для эмулятора Android, который ведет на локалхост компа
  static const String _androidBaseUrl = 'http://10.0.2.2:8000/api';

  // Обычный локалхост для Windows и браузера
  static const String _localBaseUrl = 'http://127.0.0.1:8000/api';

  static String get baseUrl {
    if (kIsWeb) return _localBaseUrl;
    // Если запущено на Android-телефоне/эмуляторе
    if (Platform.isAndroid) return _androidBaseUrl;
    // Во всех остальных случаях (Windows)
    return _localBaseUrl;
  }
}
