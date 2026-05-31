import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/permission_checker_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_provider.g.dart';

/// Layer 2 — Riverpod enforcement.
/// Usage: ref.watch(permissionCheckerProvider)(Permission.canManageClinic)
@riverpod
PermissionCheckerService permissionChecker(Ref ref) {
  final role = ref.watch(currentRoleProvider);
  return PermissionCheckerService(role);
}
