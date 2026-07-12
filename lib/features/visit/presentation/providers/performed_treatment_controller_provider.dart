import 'package:docentral/features/visit/presentation/providers/performed_treatment_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'performed_treatment_controller_provider.g.dart';

@riverpod
class PerformedTreatmentController extends _$PerformedTreatmentController {
  @override
  FutureOr<void> build() {}

  Future<void> add({
    required String visitId,
    required String toothNumber,
    required String procedureName,
    required double unitPrice,
    required int quantity,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canEditVisit),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(performedTreatmentRepositoryProvider)
          .addTreatment(
            role: role,
            actorUserId: actorUserId,
            visitId: visitId,
            toothNumber: toothNumber,
            procedureName: procedureName,
            unitPrice: unitPrice,
            quantity: quantity,
          ),
    );
  }

  Future<void> updateTreatment({
    required String treatmentId,
    required String toothNumber,
    required String procedureName,
    required double unitPrice,
    required int quantity,
  }) async {
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
          .read(performedTreatmentRepositoryProvider)
          .updateTreatment(
            role: role,
            treatmentId: treatmentId,
            toothNumber: toothNumber,
            procedureName: procedureName,
            unitPrice: unitPrice,
            quantity: quantity,
          ),
    );
  }

  Future<void> remove({required String treatmentId}) async {
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
          .read(performedTreatmentRepositoryProvider)
          .removeTreatment(role: role, treatmentId: treatmentId),
    );
  }

  Future<void> markPlannedTreatmentPerformed({
    required String visitId,
    required String plannedTreatmentId,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    final String? actorUserId = ref.read(currentUserIdProvider);
    if (role == null || actorUserId == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canEditVisit),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(performedTreatmentRepositoryProvider)
          .markPlannedTreatmentPerformed(
            role: role,
            actorUserId: actorUserId,
            visitId: visitId,
            plannedTreatmentId: plannedTreatmentId,
          ),
    );
  }
}
