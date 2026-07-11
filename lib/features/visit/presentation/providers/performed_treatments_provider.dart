import 'package:docentral/features/visit/domain/performed_treatment.dart';
import 'package:docentral/features/visit/presentation/providers/performed_treatment_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'performed_treatments_provider.g.dart';

@riverpod
Stream<List<PerformedTreatment>> performedTreatments(Ref ref, String visitId) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <PerformedTreatment>[]);

  return ref
      .watch(performedTreatmentRepositoryProvider)
      .watchForVisit(role: role, visitId: visitId);
}
