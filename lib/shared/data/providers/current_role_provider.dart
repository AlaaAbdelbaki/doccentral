import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_role_provider.g.dart';

/// Holds the authenticated user's role for the lifetime of the app session.
/// Must stay keepAlive: it's read from the router's redirect logic (and set
/// by sign-in/sign-up flows) without any widget necessarily watching it
/// continuously, so autoDispose would silently reset it to null between
/// being set and being read — see the analogous appRouterProvider gotcha.
@Riverpod(keepAlive: true)
class CurrentRole extends _$CurrentRole {
  @override
  Role? build() => null;

  void setRole(Role role) => state = role;

  void clear() => state = null;
}
