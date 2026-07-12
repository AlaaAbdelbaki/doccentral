import 'package:docentral/app.dart';
import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_repository.dart';
import 'package:docentral/features/appointment/domain/assignable_user.dart';
import 'package:docentral/features/appointment/domain/cancellation_reason.dart';
import 'package:docentral/features/appointment/presentation/providers/appointment_repository_provider.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment.dart';
import 'package:docentral/features/clinic/domain/clinic_repository.dart';
import 'package:docentral/features/clinic/presentation/providers/clinic_repository_provider.dart';
import 'package:docentral/features/clinic/presentation/providers/resolved_role_provider.dart';
import 'package:docentral/shared/data/providers/locale_provider.dart';
import 'package:docentral/shared/data/providers/shared_preferences_provider.dart';
import 'package:docentral/shared/data/router/app_router.dart';
import 'package:docentral/shared/data/router/app_routes.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAppointmentRepository implements AppointmentRepository {
  @override
  Stream<List<AppointmentRecord>> watchToday({required Role role}) =>
      Stream.value(const <AppointmentRecord>[]);

  @override
  Stream<List<AppointmentRecord>> watchRange({
    required Role role,
    required DateTime start,
    required DateTime end,
  }) => Stream.value(const <AppointmentRecord>[]);

  @override
  Stream<List<AssignableUser>> watchAssignableUsers({required Role role}) =>
      Stream.value(const <AssignableUser>[]);

  @override
  Future<String> createAppointment({
    required Role role,
    required String patientId,
    required String assignedUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
    String? notes,
    bool overrideOverlap = false,
    List<String> plannedTreatmentIds = const <String>[],
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<void> updateAppointment({
    required Role role,
    required String actorUserId,
    required String appointmentId,
    required String assignedUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
    String? notes,
    bool overrideOverlap = false,
    List<String> plannedTreatmentIds = const <String>[],
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<void> cancelAppointment({
    required Role role,
    required String actorUserId,
    required String appointmentId,
    required CancellationReason reason,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<String> rescheduleAppointment({
    required Role role,
    required String actorUserId,
    required String appointmentId,
    required String newAssignedUserId,
    required DateTime newStartTime,
    required DateTime newEndTime,
    String? newReason,
    String? newNotes,
    bool overrideOverlap = false,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Stream<int> watchNoShowCount({
    required Role role,
    required String patientId,
  }) => Stream.value(0);

  @override
  Stream<List<PlannedTreatment>> watchLinkedPlannedTreatments({
    required Role role,
    required String appointmentId,
  }) => Stream.value(const <PlannedTreatment>[]);
}

class _FakeClinicRepository implements ClinicRepository {
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

Future<ProviderContainer> _pumpSettingsPage(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  final ProviderContainer container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clinicRepositoryProvider.overrideWithValue(_FakeClinicRepository()),
      resolvedRoleProvider.overrideWith((ref) async => Role.doctor),
      appointmentRepositoryProvider.overrideWithValue(
        _FakeAppointmentRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const DocCentralApp(),
    ),
  );
  await tester.pumpAndSettle();

  final GoRouter router = container.read(appRouterProvider);
  router.goNamed(AppRoutes.settings.name);
  await tester.pumpAndSettle();

  return container;
}

void main() {
  testWidgets('defaults to French', (WidgetTester tester) async {
    final ProviderContainer container = await _pumpSettingsPage(tester);

    expect(container.read(appLocaleProvider), const Locale('fr'));
    expect(find.text('Français'), findsOneWidget);
  });

  testWidgets('switching to English updates appLocaleProvider immediately', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpSettingsPage(tester);

    await tester.tap(find.byType(DropdownButton<Locale>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(container.read(appLocaleProvider), const Locale('en'));
  });

  testWidgets('switching to Arabic flips the layout to RTL', (
    WidgetTester tester,
  ) async {
    await _pumpSettingsPage(tester);

    await tester.tap(find.byType(DropdownButton<Locale>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العربية').last);
    await tester.pumpAndSettle();

    final Directionality directionality = tester.widget(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });
}
