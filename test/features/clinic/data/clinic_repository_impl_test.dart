import 'package:docentral/features/clinic/data/clinic_repository_impl.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/domain/auth/auth_exceptions.dart';
import 'package:docentral/shared/domain/auth/auth_service.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.shouldFail = false});

  static const String userId = 'auth-user-1';
  final bool shouldFail;

  @override
  Future<String> signUp({
    required String email,
    required String password,
  }) async {
    if (shouldFail) throw const AuthException('offline');
    return userId;
  }

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    if (shouldFail) throw const AuthException('offline');
    return userId;
  }

  @override
  Future<void> signOut() async {}
}

AppDatabase _createInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createInMemoryDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('ClinicRepositoryImpl.hasLocalClinic', () {
    test('returns false before provisioning', () async {
      final ClinicRepositoryImpl repository = ClinicRepositoryImpl(
        db,
        _FakeAuthService(),
      );
      expect(await repository.hasLocalClinic(), isFalse);
    });

    test('returns true after provisioning', () async {
      final ClinicRepositoryImpl repository = ClinicRepositoryImpl(
        db,
        _FakeAuthService(),
      );
      await repository.provisionClinic(
        clinicName: 'Cabinet Test',
        dentistFirstName: 'Amine',
        dentistLastName: 'Trabelsi',
        email: 'amine@example.com',
        password: 'password123',
      );
      expect(await repository.hasLocalClinic(), isTrue);
    });
  });

  group('ClinicRepositoryImpl.provisionClinic', () {
    test('creates one Clinic, one owner User, and 3 Role records', () async {
      final ClinicRepositoryImpl repository = ClinicRepositoryImpl(
        db,
        _FakeAuthService(),
      );

      await repository.provisionClinic(
        clinicName: 'Cabinet Test',
        dentistFirstName: 'Amine',
        dentistLastName: 'Trabelsi',
        email: 'amine@example.com',
        password: 'password123',
      );

      final List<Clinic> clinics = await db.select(db.clinics).get();
      expect(clinics.length, 1);
      expect(clinics.first.name, 'Cabinet Test');
      expect(clinics.first.locale, 'fr-TN');
      expect(clinics.first.currency, 'TND');

      final List<User> users = await db.select(db.users).get();
      expect(users.length, 1);
      expect(users.first.isClinicOwner, isTrue);
      expect(users.first.authUserId, 'auth-user-1');
      expect(users.first.clinicId, clinics.first.id);

      final List<RoleRow> roles = await db.select(db.roles).get();
      expect(roles.length, 3);
      expect(roles.map((RoleRow r) => r.name).toSet(), <String>{
        'doctor',
        'assistant',
        'nurse',
      });

      final List<UserRole> userRoles = await db.select(db.userRoles).get();
      expect(userRoles.length, 1);
      expect(userRoles.first.userId, users.first.id);
      final RoleRow dentistRole = roles.firstWhere(
        (RoleRow r) => r.name == 'doctor',
      );
      expect(userRoles.first.roleId, dentistRole.id);
    });

    test('persists nothing when the auth service fails', () async {
      final ClinicRepositoryImpl repository = ClinicRepositoryImpl(
        db,
        _FakeAuthService(shouldFail: true),
      );

      await expectLater(
        repository.provisionClinic(
          clinicName: 'Cabinet Test',
          dentistFirstName: 'Amine',
          dentistLastName: 'Trabelsi',
          email: 'amine@example.com',
          password: 'password123',
        ),
        throwsA(isA<AuthException>()),
      );

      expect(await db.select(db.clinics).get(), isEmpty);
      expect(await db.select(db.users).get(), isEmpty);
      expect(await db.select(db.roles).get(), isEmpty);
      expect(await db.select(db.userRoles).get(), isEmpty);
    });
  });

  group('ClinicRepositoryImpl.resolveRole', () {
    test('resolves the dentist role for the provisioning user', () async {
      final ClinicRepositoryImpl repository = ClinicRepositoryImpl(
        db,
        _FakeAuthService(),
      );
      await repository.provisionClinic(
        clinicName: 'Cabinet Test',
        dentistFirstName: 'Amine',
        dentistLastName: 'Trabelsi',
        email: 'amine@example.com',
        password: 'password123',
      );

      final Role? role = await repository.resolveRole(_FakeAuthService.userId);
      expect(role, Role.doctor);
    });

    test('returns null for an unknown authUserId', () async {
      final ClinicRepositoryImpl repository = ClinicRepositoryImpl(
        db,
        _FakeAuthService(),
      );
      await repository.provisionClinic(
        clinicName: 'Cabinet Test',
        dentistFirstName: 'Amine',
        dentistLastName: 'Trabelsi',
        email: 'amine@example.com',
        password: 'password123',
      );

      final Role? role = await repository.resolveRole('unknown-auth-id');
      expect(role, isNull);
    });
  });
}
