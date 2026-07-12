import 'package:docentral/features/treatment_plan/domain/planned_treatment.dart';
import 'package:docentral/features/treatment_plan/presentation/providers/planned_treatment_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'planned_treatments_provider.g.dart';

@riverpod
Stream<List<PlannedTreatment>> plannedTreatments(Ref ref, String patientId) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <PlannedTreatment>[]);

  return ref
      .watch(plannedTreatmentRepositoryProvider)
      .watchForPatient(role: role, patientId: patientId);
}
