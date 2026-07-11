import 'package:docentral/features/clinic/domain/clinic_repository.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/domain/auth/auth_service.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_guard.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class ClinicRepositoryImpl implements ClinicRepository {
  ClinicRepositoryImpl(this._db, this._authService, {Uuid uuid = const Uuid()})
    : _uuid = uuid;

  final AppDatabase _db;
  final AuthService _authService;
  final Uuid _uuid;

  @override
  Future<bool> hasLocalClinic() async {
    final List<Clinic> clinics = await _db.select(_db.clinics).get();
    return clinics.isNotEmpty;
  }

  @override
  Future<String> provisionClinic({
    required String clinicName,
    required String dentistFirstName,
    required String dentistLastName,
    required String email,
    required String password,
  }) async {
    final String authUserId = await _authService.signUp(
      email: email,
      password: password,
    );

    return _db.transaction(() async {
      final DateTime now = DateTime.now();
      final String clinicId = _uuid.v4();
      final String userId = _uuid.v4();

      await _db
          .into(_db.clinics)
          .insert(
            ClinicsCompanion.insert(
              id: clinicId,
              name: clinicName,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await _db
          .into(_db.users)
          .insert(
            UsersCompanion.insert(
              id: userId,
              clinicId: clinicId,
              firstName: dentistFirstName,
              lastName: dentistLastName,
              email: email,
              authUserId: authUserId,
              isClinicOwner: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );

      String? dentistRoleId;
      for (final Role role in Role.values) {
        final String roleId = _uuid.v4();
        if (role == Role.doctor) dentistRoleId = roleId;
        await _db
            .into(_db.roles)
            .insert(
              RolesCompanion.insert(
                id: roleId,
                clinicId: clinicId,
                name: role.name,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      await _db
          .into(_db.userRoles)
          .insert(
            UserRolesCompanion.insert(
              id: _uuid.v4(),
              userId: userId,
              roleId: dentistRoleId!,
              createdAt: now,
              updatedAt: now,
            ),
          );

      return userId;
    });
  }

  Future<User?> _findUser(String authUserId) {
    return (_db.select(
      _db.users,
    )..where((t) => t.authUserId.equals(authUserId))).getSingleOrNull();
  }

  @override
  Future<Role?> resolveRole(String authUserId) async {
    final User? user = await _findUser(authUserId);
    if (user == null) return null;

    final UserRole? userRole = await (_db.select(
      _db.userRoles,
    )..where((t) => t.userId.equals(user.id))).getSingleOrNull();
    if (userRole == null) return null;

    final RoleRow? role = await (_db.select(
      _db.roles,
    )..where((t) => t.id.equals(userRole.roleId))).getSingleOrNull();
    if (role == null) return null;

    return Role.values.asNameMap()[role.name];
  }

  @override
  Future<String?> resolveUserId(String authUserId) async {
    final User? user = await _findUser(authUserId);
    return user?.id;
  }

  @override
  Future<void> addStaffUser({
    required Role actingRole,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required Role role,
  }) async {
    requirePermission(actingRole, Permission.canManageStaff);

    final String authUserId = await _authService.signUp(
      email: email,
      password: password,
    );

    await _db.transaction(() async {
      final Clinic clinic = await _db.select(_db.clinics).getSingle();
      final RoleRow roleRow =
          await (_db.select(_db.roles)..where(
                (t) => t.clinicId.equals(clinic.id) & t.name.equals(role.name),
              ))
              .getSingle();

      final DateTime now = DateTime.now();
      final String userId = _uuid.v4();

      await _db
          .into(_db.users)
          .insert(
            UsersCompanion.insert(
              id: userId,
              clinicId: clinic.id,
              firstName: firstName,
              lastName: lastName,
              email: email,
              authUserId: authUserId,
              isClinicOwner: const Value(false),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await _db
          .into(_db.userRoles)
          .insert(
            UserRolesCompanion.insert(
              id: _uuid.v4(),
              userId: userId,
              roleId: roleRow.id,
              createdAt: now,
              updatedAt: now,
            ),
          );
    });
  }
}
