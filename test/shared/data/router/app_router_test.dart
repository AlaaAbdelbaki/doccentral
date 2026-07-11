import 'package:docentral/features/clinic/domain/clinic_repository.dart';
import 'package:docentral/features/clinic/presentation/providers/clinic_repository_provider.dart';
import 'package:docentral/features/clinic/presentation/providers/resolved_role_provider.dart';
import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:docentral/features/patient/domain/patient_repository.dart';
import 'package:docentral/features/patient/presentation/providers/patient_repository_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/shared_preferences_provider.dart';
import 'package:docentral/shared/data/router/app_router.dart';
import 'package:docentral/shared/data/router/app_routes.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePatientRepository implements PatientRepository {
  @override
  Stream<List<PatientRecord>> watchAll({
    required Role role,
    String query = '',
  }) => Stream.value(const <PatientRecord>[]);

  @override
  Future<void> create({
    required Role role,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String phone,
    String? email,
    String? historyNotes,
  }) => throw UnimplementedError('not exercised by this test');
}

class _FakeClinicRepository implements ClinicRepository {
  _FakeClinicRepository({required this.hasClinic});

  final bool hasClinic;

  @override
  Future<bool> hasLocalClinic() async => hasClinic;

  @override
  Future<String> provisionClinic({
    required String clinicName,
    required String dentistFirstName,
    required String dentistLastName,
    required String email,
    required String password,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<Role?> resolveRole(String authUserId) =>
      throw UnimplementedError('not exercised by this test');

  @override
  Future<String?> resolveUserId(String authUserId) =>
      throw UnimplementedError('not exercised by this test');

  @override
  Future<void> addStaffUser({
    required Role actingRole,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required Role role,
  }) => throw UnimplementedError('not exercised by this test');
}

Future<GoRouter> _pumpRouter(
  WidgetTester tester, {
  bool hasClinic = true,
  Role? role = Role.doctor,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final ProviderContainer container = ProviderContainer(
    overrides: [
      clinicRepositoryProvider.overrideWithValue(
        _FakeClinicRepository(hasClinic: hasClinic),
      ),
      resolvedRoleProvider.overrideWith((ref) async => role),
      patientRepositoryProvider.overrideWithValue(_FakePatientRepository()),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  addTearDown(container.dispose);
  if (role != null) {
    container.read(currentRoleProvider.notifier).setRole(role);
  }
  final GoRouter router = container.read(appRouterProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('starts on the calendar destination', (
    WidgetTester tester,
  ) async {
    await _pumpRouter(tester);

    expect(find.text("Today's Calendar"), findsWidgets);
  });

  testWidgets('going to each registered route shows its page', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpRouter(tester);

    router.go(AppRoutes.patients.path);
    await tester.pumpAndSettle();
    expect(find.text('Patients'), findsWidgets);

    router.go(AppRoutes.inventory.path);
    await tester.pumpAndSettle();
    expect(find.text('Inventory'), findsWidgets);

    router.go(AppRoutes.dayCloseout.path);
    await tester.pumpAndSettle();
    expect(find.text('Day Closeout'), findsWidgets);

    router.go(AppRoutes.settings.path);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('redirects to sign-up when no local clinic exists', (
    WidgetTester tester,
  ) async {
    await _pumpRouter(tester, hasClinic: false, role: null);

    expect(find.text('Create your clinic'), findsOneWidget);
  });

  testWidgets('redirects away from sign-up once a clinic exists', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpRouter(tester, hasClinic: true);

    router.go(AppRoutes.signUp.path);
    await tester.pumpAndSettle();

    expect(find.text("Today's Calendar"), findsWidgets);
    expect(find.text('Create your clinic'), findsNothing);
  });

  testWidgets(
    'redirects to sign-in when a clinic exists but no session is active',
    (WidgetTester tester) async {
      await _pumpRouter(tester, hasClinic: true, role: null);

      expect(find.text('Sign in'), findsWidgets);
    },
  );

  testWidgets('redirects away from sign-in once a role is resolved', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpRouter(
      tester,
      hasClinic: true,
      role: Role.doctor,
    );

    router.go(AppRoutes.signIn.path);
    await tester.pumpAndSettle();

    expect(find.text("Today's Calendar"), findsWidgets);
  });

  testWidgets('blocks a non-Dentist role from the add-staff route', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpRouter(tester, role: Role.assistant);

    router.go(AppRoutes.addStaffUser.path);
    await tester.pumpAndSettle();

    expect(find.text('Add staff'), findsNothing);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('allows the Dentist role onto the add-staff route', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await _pumpRouter(tester, role: Role.doctor);

    router.go(AppRoutes.addStaffUser.path);
    await tester.pumpAndSettle();

    expect(find.text('Add staff'), findsWidgets);
  });
}
