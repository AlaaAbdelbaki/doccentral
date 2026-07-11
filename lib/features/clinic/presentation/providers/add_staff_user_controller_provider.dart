import 'package:docentral/features/clinic/presentation/providers/clinic_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/auth/auth_exceptions.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'add_staff_user_controller_provider.g.dart';

@riverpod
class AddStaffUserController extends _$AddStaffUserController {
  @override
  FutureOr<void> build() {}

  Future<void> addStaffUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required Role role,
  }) async {
    final Role? actingRole = ref.read(currentRoleProvider);
    if (actingRole == null) {
      state = AsyncError(
        const AuthException('Not signed in'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(clinicRepositoryProvider)
          .addStaffUser(
            actingRole: actingRole,
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            role: role,
          ),
    );
  }
}
