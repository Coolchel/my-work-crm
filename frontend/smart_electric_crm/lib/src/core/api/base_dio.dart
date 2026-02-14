import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/api_urls.dart';

part 'base_dio.g.dart';

// Base Dio for Auth Repository (no interceptors to avoid cycles)
@riverpod
Dio baseDio(Ref ref) {
  final options = BaseOptions(
    baseUrl: ApiUrls.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
  return Dio(options);
}
