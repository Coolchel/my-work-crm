import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../data/repositories/template_repository.dart';
import '../../data/models/template_models.dart';

// Repository Provider
final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return TemplateRepository(ref.watch(dioProvider));
});

// --- Data Providers ---

final workTemplatesProvider = FutureProvider<List<WorkTemplate>>((ref) async {
  return ref.watch(templateRepositoryProvider).getWorkTemplates();
});

final materialTemplatesProvider =
    FutureProvider<List<MaterialTemplate>>((ref) async {
  return ref.watch(templateRepositoryProvider).getMaterialTemplates();
});

final powerShieldTemplatesProvider =
    FutureProvider<List<PowerShieldTemplate>>((ref) async {
  return ref.watch(templateRepositoryProvider).getPowerShieldTemplates();
});

final multimediaTemplatesProvider =
    FutureProvider<List<MultimediaTemplate>>((ref) async {
  return ref.watch(templateRepositoryProvider).getMultimediaTemplates();
});
