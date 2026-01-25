import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:smart_electric_crm/src/features/projects/data/repositories/project_repository.dart';

// Dio Provider (можно вынести в core)
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8000/api', // Для Windows
    // baseUrl: 'http://10.0.2.2:8000/api', // Для Android Emulator
  ));
  return dio;
});

// Project Repository Provider
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ProjectRepository(dio: dio);
});
