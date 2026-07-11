import 'package:docentral/shared/domain/rbac/role.dart';

/// A staff member who can be assigned to an appointment.
class AssignableUser {
  const AssignableUser({
    required this.id,
    required this.name,
    required this.role,
  });

  final String id;
  final String name;
  final Role role;
}
