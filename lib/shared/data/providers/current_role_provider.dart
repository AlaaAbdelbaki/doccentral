import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_role_provider.g.dart';

/// Holds the authenticated user's role.
/// Replaced by a real implementation in Epic 2 (auth flow).
@riverpod
class CurrentRole extends _$CurrentRole {
  @override
  Role? build() => null;

  void setRole(Role role) => state = role;

  void clear() => state = null;
}
