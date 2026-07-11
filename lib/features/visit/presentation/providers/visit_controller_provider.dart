import 'package:docentral/features/visit/presentation/providers/visit_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'visit_controller_provider.g.dart';

@riverpod
class VisitController extends _$VisitController {
  @override
  FutureOr<void> build() {}

  Future<void> checkIn({required String appointmentId}) async {
    final Role? role = ref.read(currentRoleProvider);
    if (role == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canCheckInPatient),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(visitRepositoryProvider)
          .checkIn(role: role, appointmentId: appointmentId),
    );
  }

  Future<void> startProgress({required String appointmentId}) async {
    final Role? role = ref.read(currentRoleProvider);
    if (role == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canEditVisit),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(visitRepositoryProvider)
          .startProgress(role: role, appointmentId: appointmentId),
    );
  }

  Future<void> updateClinicalRecord({
    required String visitId,
    String? diagnosis,
    String? clinicalNotes,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    if (role == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canAddClinicalNotes),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(visitRepositoryProvider)
          .updateClinicalRecord(
            role: role,
            visitId: visitId,
            diagnosis: diagnosis,
            clinicalNotes: clinicalNotes,
          ),
    );
  }

  Future<void> completeVisit({required String visitId}) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canCompleteVisit),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(visitRepositoryProvider)
          .completeVisit(
            role: role,
            actorUserId: actorUserId,
            visitId: visitId,
          ),
    );
  }

  Future<void> unlockVisit({
    required String visitId,
    required String reason,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canUnlockVisit),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(visitRepositoryProvider)
          .unlockVisit(
            role: role,
            actorUserId: actorUserId,
            visitId: visitId,
            reason: reason,
          ),
    );
  }
}
