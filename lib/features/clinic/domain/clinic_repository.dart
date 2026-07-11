import 'package:docentral/shared/domain/rbac/role.dart';

abstract class ClinicRepository {
  Future<bool> hasLocalClinic();

  /// Returns the newly created local Users.id for the dentist.
  Future<String> provisionClinic({
    required String clinicName,
    required String dentistFirstName,
    required String dentistLastName,
    required String email,
    required String password,
  });

  /// Resolves the local Role assigned to the User linked to [authUserId],
  /// or null if no such User (or no assigned Role) exists locally.
  Future<Role?> resolveRole(String authUserId);

  /// Resolves the local Users.id linked to [authUserId], or null if no such
  /// User exists locally. Used to attribute audit/edit-log entries.
  Future<String?> resolveUserId(String authUserId);

  /// Adds a new staff User (Assistant or Nurse) to the local Clinic.
  /// Throws [PermissionDeniedException] unless [actingRole] can manage staff.
  Future<void> addStaffUser({
    required Role actingRole,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required Role role,
  });
}
