import 'package:docentral/features/clinic/presentation/providers/clinic_repository_provider.dart';
import 'package:docentral/shared/data/providers/auth_service_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/auth/auth_exceptions.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_in_controller_provider.g.dart';

@riverpod
class SignInController extends _$SignInController {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final String authUserId = await ref
          .read(authServiceProvider)
          .signIn(email: email, password: password);
      final Role? role = await ref
          .read(clinicRepositoryProvider)
          .resolveRole(authUserId);
      if (role == null) {
        throw const AuthException(
          'No local role found for this account on this device (sync is not yet implemented).',
        );
      }
      final String? userId = await ref
          .read(clinicRepositoryProvider)
          .resolveUserId(authUserId);
      ref.read(currentRoleProvider.notifier).setRole(role);
      if (userId != null) {
        ref.read(currentUserIdProvider.notifier).setUserId(userId);
      }
    });
  }
}
