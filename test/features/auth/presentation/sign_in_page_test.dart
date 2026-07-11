import 'package:docentral/features/auth/presentation/sign_in_page.dart';
import 'package:docentral/features/clinic/domain/clinic_repository.dart';
import 'package:docentral/features/clinic/presentation/providers/clinic_repository_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/auth_service_provider.dart';
import 'package:docentral/shared/domain/auth/auth_exceptions.dart';
import 'package:docentral/shared/domain/auth/auth_service.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.shouldFail = false});

  final bool shouldFail;

  @override
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    if (shouldFail) throw const AuthException('offline');
    return 'auth-user-1';
  }

  @override
  Future<String> signUp({required String email, required String password}) =>
      throw UnimplementedError('not exercised by this test');

  @override
  Future<void> signOut() async {}
}

class _FakeClinicRepository implements ClinicRepository {
  _FakeClinicRepository({this.role = Role.doctor});

  final Role? role;

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
  Future<Role?> resolveRole(String authUserId) async => role;

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
  }) => throw UnimplementedError('not exercised by this test');
}

Future<void> _pumpSignInPage(
  WidgetTester tester, {
  bool authShouldFail = false,
  Role? resolvedRole = Role.doctor,
}) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      authServiceProvider.overrideWithValue(
        _FakeAuthService(shouldFail: authShouldFail),
      ),
      clinicRepositoryProvider.overrideWithValue(
        _FakeClinicRepository(role: resolvedRole),
      ),
    ],
  );
  addTearDown(container.dispose);

  final GoRouter router = GoRouter(
    initialLocation: '/sign-in',
    routes: [
      GoRoute(
        path: '/sign-in',
        name: 'signIn',
        builder: (context, state) => const SignInPage(),
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
}

void main() {
  testWidgets('shows required-field errors when submitted empty', (
    WidgetTester tester,
  ) async {
    await _pumpSignInPage(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsWidgets);
  });

  testWidgets('successful sign-in navigates to calendar', (
    WidgetTester tester,
  ) async {
    await _pumpSignInPage(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'amine@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Calendar Page'), findsOneWidget);
  });

  testWidgets('shows an error message when the auth call fails', (
    WidgetTester tester,
  ) async {
    await _pumpSignInPage(tester, authShouldFail: true);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'amine@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not sign in. Check your credentials and connection.'),
      findsOneWidget,
    );
  });

  testWidgets('shows an error message when no local role can be resolved', (
    WidgetTester tester,
  ) async {
    await _pumpSignInPage(tester, resolvedRole: null);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'amine@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not sign in. Check your credentials and connection.'),
      findsOneWidget,
    );
  });
}
