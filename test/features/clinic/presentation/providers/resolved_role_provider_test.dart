import 'package:docentral/features/clinic/domain/clinic_repository.dart';
import 'package:docentral/features/clinic/presentation/providers/clinic_repository_provider.dart';
import 'package:docentral/features/clinic/presentation/providers/resolved_role_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_session_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeClinicRepository implements ClinicRepository {
  _FakeClinicRepository({this.role, this.userId});

  final Role? role;
  final String? userId;

  @override
  Future<bool> hasLocalClinic() => throw UnimplementedError('not exercised');

  @override
  Future<String> provisionClinic({
    required String clinicName,
    required String dentistFirstName,
    required String dentistLastName,
    required String email,
    required String password,
  }) => throw UnimplementedError('not exercised');

  @override
  Future<Role?> resolveRole(String authUserId) async => role;

  @override
  Future<String?> resolveUserId(String authUserId) async => userId;

  @override
  Future<void> addStaffUser({
    required Role actingRole,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required Role role,
  }) => throw UnimplementedError('not exercised');
}

Session _fakeSession(String authUserId) => Session(
  accessToken: 'fake-token',
  tokenType: 'bearer',
  user: User(
    id: authUserId,
    appMetadata: const <String, dynamic>{},
    userMetadata: const <String, dynamic>{},
    aud: 'authenticated',
    createdAt: DateTime(2026).toIso8601String(),
  ),
);

void main() {
  test(
    'a session restored automatically (no interactive sign-in) still populates CurrentRole/CurrentUserId',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          currentSessionProvider.overrideWith(
            (Ref ref) => Stream.value(_fakeSession('auth-user-1')),
          ),
          clinicRepositoryProvider.overrideWithValue(
            _FakeClinicRepository(role: Role.assistant, userId: 'user-1'),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(
        resolvedRoleProvider,
        (AsyncValue<Role?>? previous, AsyncValue<Role?> next) {},
      );

      final Role? role = await container.read(resolvedRoleProvider.future);

      expect(role, Role.assistant);
      expect(container.read(currentRoleProvider), Role.assistant);
      expect(container.read(currentUserIdProvider), 'user-1');
    },
  );

  test(
    'clears CurrentRole/CurrentUserId when there is no active session',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          currentSessionProvider.overrideWith((Ref ref) => Stream.value(null)),
          clinicRepositoryProvider.overrideWithValue(_FakeClinicRepository()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(
        resolvedRoleProvider,
        (AsyncValue<Role?>? previous, AsyncValue<Role?> next) {},
      );
      container.read(currentRoleProvider.notifier).setRole(Role.doctor);
      container.read(currentUserIdProvider.notifier).setUserId('stale-user');

      final Role? role = await container.read(resolvedRoleProvider.future);

      expect(role, isNull);
      expect(container.read(currentRoleProvider), isNull);
      expect(container.read(currentUserIdProvider), isNull);
    },
  );

  test(
    'leaves CurrentRole/CurrentUserId unset when the session has no local role',
    () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          currentSessionProvider.overrideWith(
            (Ref ref) => Stream.value(_fakeSession('auth-user-2')),
          ),
          clinicRepositoryProvider.overrideWithValue(_FakeClinicRepository()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(
        resolvedRoleProvider,
        (AsyncValue<Role?>? previous, AsyncValue<Role?> next) {},
      );

      final Role? role = await container.read(resolvedRoleProvider.future);

      expect(role, isNull);
      expect(container.read(currentRoleProvider), isNull);
      expect(container.read(currentUserIdProvider), isNull);
    },
  );
}
