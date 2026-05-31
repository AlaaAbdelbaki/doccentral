import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_checker.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

/// Layer 3 — Domain enforcement.
/// Call at the start of any service method that requires a permission.
/// Throws [PermissionDeniedException] if the role lacks the permission.
void requirePermission(Role role, Permission permission) {
  if (!hasPermission(role, permission)) {
    throw PermissionDeniedException(permission);
  }
}
