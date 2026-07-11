import 'package:docentral/features/appointment/domain/assignable_user.dart';
import 'package:docentral/features/appointment/presentation/providers/appointment_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'assignable_users_provider.g.dart';

@riverpod
Stream<List<AssignableUser>> assignableUsers(Ref ref) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <AssignableUser>[]);

  return ref
      .watch(appointmentRepositoryProvider)
      .watchAssignableUsers(role: role);
}
