import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/api_urls.dart';

// Указываем имя файла, который сгенерирует робот
part 'dio_client.g.dart';

// Создаем провайдер - источник объекта Dio для всего приложения
@riverpod
Dio dio(Ref ref) {
  final options = BaseOptions(
    baseUrl: ApiUrls.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  final dio = Dio(options);

  // Добавляем логирование, чтобы видеть запросы в консоли
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) => debugPrint('🌐 API LOG: $obj'),
  ));

  return dio;
}
