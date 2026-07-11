import 'package:docentral/features/appointment/presentation/providers/appointment_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'no_show_pattern_provider.g.dart';

/// A patient is flagged once they have 2 or more `no_show` cancellations.
const int noShowPatternThreshold = 2;

@riverpod
Stream<bool> hasNoShowPattern(Ref ref, String patientId) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(false);

  return ref
      .watch(appointmentRepositoryProvider)
      .watchNoShowCount(role: role, patientId: patientId)
      .map((int count) => count >= noShowPatternThreshold);
}
