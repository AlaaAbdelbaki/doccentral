import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_checker.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

/// Layer 1 — Router enforcement.
/// Used inside GoRouter redirect callbacks.
/// Returns the redirect path if access is denied, null if allowed.
String? permissionRouteGuard({
  required Role? role,
  required Permission required,
  required String redirectTo,
}) {
  if (role == null) return redirectTo;
  if (!hasPermission(role, required)) return redirectTo;
  return null;
}
