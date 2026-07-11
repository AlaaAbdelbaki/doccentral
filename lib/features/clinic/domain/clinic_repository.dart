import 'package:docentral/shared/domain/rbac/role.dart';

abstract class ClinicRepository {
  Future<bool> hasLocalClinic();

  Future<void> provisionClinic({
    required String clinicName,
    required String dentistFirstName,
    required String dentistLastName,
    required String email,
    required String password,
  });

  /// Resolves the local Role assigned to the User linked to [authUserId],
  /// or null if no such User (or no assigned Role) exists locally.
  Future<Role?> resolveRole(String authUserId);
}
