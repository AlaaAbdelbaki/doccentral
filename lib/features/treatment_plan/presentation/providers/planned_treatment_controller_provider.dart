import 'package:docentral/features/treatment_plan/presentation/providers/planned_treatment_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'planned_treatment_controller_provider.g.dart';

@riverpod
class PlannedTreatmentController extends _$PlannedTreatmentController {
  @override
  FutureOr<void> build() {}

  Future<void> add({
    required String patientId,
    required String procedureName,
    required String toothNumber,
    required double estimatedUnitPrice,
    DateTime? targetDate,
  }) async {
    final Role? role = ref.read(currentRoleProvider);
    if (role == null) {
      state = AsyncError(
        const PermissionDeniedException(Permission.canManageTreatmentPlan),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(plannedTreatmentRepositoryProvider)
          .addPlannedTreatment(
            role: role,
            patientId: patientId,
            procedureName: procedureName,
            toothNumber: toothNumber,
            estimatedUnitPrice: estimatedUnitPrice,
            targetDate: targetDate,
          ),
    );
  }
}
