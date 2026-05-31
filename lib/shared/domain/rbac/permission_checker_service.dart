import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_checker.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

/// Value object that encapsulates permission checks for a given role.
/// Obtained from [permissionCheckerProvider] — never instantiated directly in UI.
class PermissionCheckerService {
  const PermissionCheckerService(this._role);

  final Role? _role;

  bool call(Permission permission) {
    if (_role == null) return false;
    return hasPermission(_role, permission);
  }
}
