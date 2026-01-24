import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/api/dio_client.dart';
import '../../data/repositories/engineering_repository.dart';
import '../../data/models/shield_group_model.dart';
import '../../data/models/led_zone_model.dart';
import '../../data/models/shield_template_model.dart';
import '../../data/models/led_template_model.dart';

part 'engineering_providers.g.dart';

/// Провайдер репозитория
@riverpod
EngineeringRepository engineeringRepository(EngineeringRepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  return EngineeringRepository(dio: dio);
}

/// Провайдер для получения списка групп щита проекта
@riverpod
class ShieldGroups extends _$ShieldGroups {
  @override
  FutureOr<List<ShieldGroupModel>> build(String projectId) {
    return ref
        .watch(engineeringRepositoryProvider)
        .fetchShieldGroups(projectId);
  }

  Future<void> applyTemplate(int templateId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(engineeringRepositoryProvider)
          .applyShieldTemplate(projectId, templateId);
      // После успешного применения шаблона обновляем список
      return ref
          .read(engineeringRepositoryProvider)
          .fetchShieldGroups(projectId);
    });
  }

  Future<void> add(String device, String zone) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(engineeringRepositoryProvider).addShieldGroup(projectId, {
        'device': device,
        'zone': zone,
      });
      return ref
          .read(engineeringRepositoryProvider)
          .fetchShieldGroups(projectId);
    });
  }

  Future<void> updateShieldGroup(int id, String device, String zone) async {
    await ref.read(engineeringRepositoryProvider).updateShieldGroup(id, {
      'device': device,
      'zone': zone,
    });
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await ref.read(engineeringRepositoryProvider).deleteShieldGroup(id);
    ref.invalidateSelf();
  }
}

/// Провайдер для получения списка зон LED проекта
@riverpod
class LedZones extends _$LedZones {
  @override
  FutureOr<List<LedZoneModel>> build(String projectId) {
    return ref.watch(engineeringRepositoryProvider).fetchLedZones(projectId);
  }

  Future<void> applyTemplate(int templateId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(engineeringRepositoryProvider)
          .applyLedTemplate(projectId, templateId);
      // После успешного применения шаблона обновляем список
      return ref.read(engineeringRepositoryProvider).fetchLedZones(projectId);
    });
  }

  Future<void> add(String transformer, String zone) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(engineeringRepositoryProvider).addLedZone(projectId, {
        'transformer': transformer,
        'zone': zone,
      });
      return ref.read(engineeringRepositoryProvider).fetchLedZones(projectId);
    });
  }

  Future<void> updateLedZone(int id, String transformer, String zone) async {
    await ref.read(engineeringRepositoryProvider).updateLedZone(id, {
      'transformer': transformer,
      'zone': zone,
    });
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await ref.read(engineeringRepositoryProvider).deleteLedZone(id);
    ref.invalidateSelf();
  }
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
