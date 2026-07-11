import 'package:docentral/features/clinic/domain/clinic_repository.dart';
import 'package:docentral/features/clinic/presentation/providers/clinic_repository_provider.dart';
import 'package:docentral/features/clinic/presentation/sign_up_page.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/domain/auth/auth_exceptions.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeClinicRepository implements ClinicRepository {
  _FakeClinicRepository({this.shouldFail = false});

  final bool shouldFail;
  bool provisioned = false;
  String? lastClinicName;

  @override
  Future<bool> hasLocalClinic() async => provisioned;

  @override
  Future<void> provisionClinic({
    required String clinicName,
    required String dentistFirstName,
    required String dentistLastName,
    required String email,
    required String password,
  }) async {
    if (shouldFail) throw const AuthException('offline');
    lastClinicName = clinicName;
    provisioned = true;
  }

  @override
  Future<Role?> resolveRole(String authUserId) async => Role.doctor;
}

Future<ProviderContainer> _pumpSignUpPage(
  WidgetTester tester,
  _FakeClinicRepository fakeRepository,
) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [clinicRepositoryProvider.overrideWithValue(fakeRepository)],
  );
  addTearDown(container.dispose);

  final GoRouter router = GoRouter(
    initialLocation: '/sign-up',
    routes: [
      GoRoute(
        path: '/sign-up',
        name: 'signUp',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) => const Text('Calendar Page'),
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
  return container;
}

void main() {
  testWidgets('shows required-field errors when submitted empty', (
    WidgetTester tester,
  ) async {
    await _pumpSignUpPage(tester, _FakeClinicRepository());

    await tester.tap(find.text('Create clinic'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsWidgets);
  });

  testWidgets('shows a mismatch error when passwords differ', (
    WidgetTester tester,
  ) async {
    await _pumpSignUpPage(tester, _FakeClinicRepository());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Clinic name'),
      'Cabinet Test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'First name'),
      'Amine',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Last name'),
      'Trabelsi',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'amine@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'different123',
    );

    await tester.tap(find.text('Create clinic'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('successful submit navigates to calendar', (
    WidgetTester tester,
  ) async {
    final _FakeClinicRepository fakeRepository = _FakeClinicRepository();
    await _pumpSignUpPage(tester, fakeRepository);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Clinic name'),
      'Cabinet Test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'First name'),
      'Amine',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Last name'),
      'Trabelsi',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'amine@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'password123',
    );

    await tester.tap(find.text('Create clinic'));
    await tester.pumpAndSettle();

    expect(fakeRepository.lastClinicName, 'Cabinet Test');
    expect(find.text('Calendar Page'), findsOneWidget);
  });

  testWidgets('shows an error message when provisioning fails', (
    WidgetTester tester,
  ) async {
    await _pumpSignUpPage(tester, _FakeClinicRepository(shouldFail: true));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Clinic name'),
      'Cabinet Test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'First name'),
      'Amine',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Last name'),
      'Trabelsi',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'amine@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'password123',
    );

    await tester.tap(find.text('Create clinic'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not create your clinic. Check your connection and try again.',
      ),
      findsOneWidget,
    );
  });
}
