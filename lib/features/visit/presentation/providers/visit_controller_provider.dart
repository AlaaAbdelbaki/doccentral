import 'package:docentral/features/visit/presentation/providers/visit_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
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
}
