import 'package:docentral/features/visit/domain/visit_record.dart';
import 'package:docentral/features/visit/presentation/providers/visit_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'visit_for_appointment_provider.g.dart';

@riverpod
Stream<VisitRecord?> visitForAppointment(Ref ref, String appointmentId) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(null);

  return ref
      .watch(visitRepositoryProvider)
      .watchVisitForAppointment(role: role, appointmentId: appointmentId);
}
