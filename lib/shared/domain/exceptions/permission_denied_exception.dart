import 'package:docentral/shared/domain/rbac/permission.dart';

class PermissionDeniedException implements Exception {
  const PermissionDeniedException(this.permission);

  final Permission permission;

  @override
  String toString() => 'PermissionDeniedException: missing $permission';
}
