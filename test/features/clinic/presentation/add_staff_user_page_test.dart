import 'package:docentral/features/clinic/domain/clinic_repository.dart';
import 'package:docentral/features/clinic/presentation/add_staff_user_page.dart';
import 'package:docentral/features/clinic/presentation/providers/clinic_repository_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/auth/auth_exceptions.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeClinicRepository implements ClinicRepository {
  _FakeClinicRepository({this.shouldFail = false});

  final bool shouldFail;
  Role? lastRole;
  String? lastEmail;

  @override
  Future<bool> hasLocalClinic() async => true;

  @override
  Future<String> provisionClinic({
    required String clinicName,
    required String dentistFirstName,
    required String dentistLastName,
    required String email,
    required String password,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<Role?> resolveRole(String authUserId) async => Role.doctor;

  @override
  Future<String?> resolveUserId(String authUserId) async => 'user-1';

  @override
  Future<void> addStaffUser({
    required Role actingRole,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required Role role,
  }) async {
    if (shouldFail) throw const AuthException('offline');
    lastRole = role;
    lastEmail = email;
  }
}

Future<_FakeClinicRepository> _pumpAddStaffPage(
  WidgetTester tester, {
  bool shouldFail = false,
}) async {
  final _FakeClinicRepository fakeRepository = _FakeClinicRepository(
    shouldFail: shouldFail,
  );
  final ProviderContainer container = ProviderContainer(
    overrides: [clinicRepositoryProvider.overrideWithValue(fakeRepository)],
  );
  addTearDown(container.dispose);
  container.read(currentRoleProvider.notifier).setRole(Role.doctor);

  final GoRouter router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/add-staff',
        name: 'addStaffUser',
        builder: (context, state) => const AddStaffUserPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const Text('Settings Page'),
      ),
    ],
  );

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

  // Push (not go) so there's a prior page for the page's own context.pop()
  // to return to on success, matching how it's reached from Settings.
  router.pushNamed('addStaffUser');
  await tester.pumpAndSettle();

  return fakeRepository;
}

void main() {
  testWidgets('shows required-field errors when submitted empty', (
    WidgetTester tester,
  ) async {
    await _pumpAddStaffPage(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Add staff'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsWidgets);
  });

  testWidgets('defaults to Assistant role and submits successfully', (
    WidgetTester tester,
  ) async {
    final _FakeClinicRepository fakeRepository = await _pumpAddStaffPage(
      tester,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'First name'),
      'Sarra',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Last name'),
      'Ben Youssef',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'sarra@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Initial password'),
      'password123',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Add staff'));
    await tester.pumpAndSettle();

    expect(fakeRepository.lastRole, Role.assistant);
    expect(fakeRepository.lastEmail, 'sarra@example.com');
  });

  testWidgets('can select the Nurse role', (WidgetTester tester) async {
    final _FakeClinicRepository fakeRepository = await _pumpAddStaffPage(
      tester,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'First name'),
      'Sarra',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Last name'),
      'Ben Youssef',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'sarra@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Initial password'),
      'password123',
    );

    await tester.tap(find.byType(DropdownButtonFormField<Role>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nurse').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add staff'));
    await tester.pumpAndSettle();

    expect(fakeRepository.lastRole, Role.nurse);
  });

  testWidgets('shows an error message when adding staff fails', (
    WidgetTester tester,
  ) async {
    await _pumpAddStaffPage(tester, shouldFail: true);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'First name'),
      'Sarra',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Last name'),
      'Ben Youssef',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'sarra@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Initial password'),
      'password123',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Add staff'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not add this staff member. Check the details and your connection.',
      ),
      findsOneWidget,
    );
  });
}
