import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/api/dio_client.dart';
import '../../data/repositories/engineering_repository.dart';
import '../../data/models/shield_template_model.dart';
import '../../data/models/led_template_model.dart';

part 'engineering_providers.g.dart';

/// Провайдер репозитория
@riverpod
EngineeringRepository engineeringRepository(EngineeringRepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  return EngineeringRepository(dio: dio);
}

/// Провайдер списка шаблонов щитов
@riverpod
Future<List<ShieldTemplateModel>> shieldTemplates(ShieldTemplatesRef ref) {
  return ref.watch(engineeringRepositoryProvider).fetchShieldTemplates();
}

/// Провайдер списка шаблонов LED
@riverpod
Future<List<LedTemplateModel>> ledTemplates(LedTemplatesRef ref) {
  return ref.watch(engineeringRepositoryProvider).fetchLedTemplates();
}
