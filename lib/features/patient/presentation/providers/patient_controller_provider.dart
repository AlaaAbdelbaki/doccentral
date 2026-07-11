import 'package:docentral/features/patient/presentation/providers/patient_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'patient_controller_provider.g.dart';

@riverpod
class PatientController extends _$PatientController {
  @override
  FutureOr<void> build() {}

  Future<void> create({
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String phone,
    String? email,
    String? historyNotes,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    if (role == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canCreatePatient),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(patientRepositoryProvider)
          .create(
            role: role,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            phone: phone,
            email: email,
            historyNotes: historyNotes,
          ),
    );
  }

  Future<void> updatePatient({
    required String patientId,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String phone,
    String? email,
    String? historyNotes,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canEditPatient),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(patientRepositoryProvider)
          .updatePatient(
            role: role,
            actorUserId: actorUserId,
            patientId: patientId,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            phone: phone,
            email: email,
            historyNotes: historyNotes,
          ),
    );
  }

  Future<void> deletePatient({required String patientId}) async {
    final Role? role = ref.read(currentRoleProvider);
    if (role == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canDeletePatient),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(patientRepositoryProvider)
          .deletePatient(role: role, patientId: patientId),
    );
  }
}
