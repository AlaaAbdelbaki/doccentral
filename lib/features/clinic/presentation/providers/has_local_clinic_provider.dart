import 'package:docentral/features/clinic/presentation/providers/clinic_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'has_local_clinic_provider.g.dart';

@riverpod
Future<bool> hasLocalClinic(Ref ref) {
  return ref.watch(clinicRepositoryProvider).hasLocalClinic();
}
