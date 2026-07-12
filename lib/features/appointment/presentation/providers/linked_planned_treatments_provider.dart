import 'package:docentral/features/appointment/presentation/providers/appointment_repository_provider.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'linked_planned_treatments_provider.g.dart';

@riverpod
Stream<List<PlannedTreatment>> linkedPlannedTreatments(
  Ref ref,
  String appointmentId,
) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <PlannedTreatment>[]);

  return ref
      .watch(appointmentRepositoryProvider)
      .watchLinkedPlannedTreatments(role: role, appointmentId: appointmentId);
}
