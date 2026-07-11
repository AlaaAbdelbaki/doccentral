import 'package:docentral/features/clinic/presentation/providers/clinic_repository_provider.dart';
import 'package:docentral/features/clinic/presentation/providers/has_local_clinic_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clinic_provisioning_controller_provider.g.dart';

@riverpod
class ClinicProvisioningController extends _$ClinicProvisioningController {
  @override
  FutureOr<void> build() {}

  Future<void> signUp({
    required String clinicName,
    required String dentistFirstName,
    required String dentistLastName,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(clinicRepositoryProvider)
          .provisionClinic(
            clinicName: clinicName,
            dentistFirstName: dentistFirstName,
            dentistLastName: dentistLastName,
            email: email,
            password: password,
          );
      ref.read(currentRoleProvider.notifier).setRole(Role.doctor);
      ref.invalidate(hasLocalClinicProvider);
    });
  }
}
