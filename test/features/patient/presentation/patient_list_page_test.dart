import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_repository.dart';
import 'package:docentral/features/appointment/domain/assignable_user.dart';
import 'package:docentral/features/appointment/domain/cancellation_reason.dart';
import 'package:docentral/features/appointment/presentation/providers/appointment_repository_provider.dart';
import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:docentral/features/patient/domain/patient_repository.dart';
import 'package:docentral/features/patient/presentation/patient_list_page.dart';
import 'package:docentral/features/patient/presentation/providers/patient_repository_provider.dart';
import 'package:docentral/features/visit/domain/visit_record.dart';
import 'package:docentral/features/visit/domain/visit_repository.dart';
import 'package:docentral/features/visit/domain/visit_status.dart';
import 'package:docentral/features/visit/presentation/providers/visit_repository_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

class _FakeVisitRepository implements VisitRepository {
  _FakeVisitRepository({this.visits = const <VisitRecord>[]});

  final List<VisitRecord> visits;

  @override
  Future<String> checkIn({required Role role, required String appointmentId}) =>
      throw UnimplementedError('not exercised by this test');

  @override
  Stream<List<VisitRecord>> watchRecentVisits({
    required Role role,
    required String patientId,
    int limit = 3,
  }) => Stream.value(
    visits.where((VisitRecord v) => v.patientId == patientId).toList(),
  );

  @override
  Stream<VisitRecord?> watchVisitForAppointment({
    required Role role,
    required String appointmentId,
  }) => Stream.value(null);

  @override
  Future<void> startProgress({
    required Role role,
    required String appointmentId,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<void> updateClinicalRecord({
    required Role role,
    required String visitId,
    String? diagnosis,
    String? clinicalNotes,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<String> completeVisit({
    required Role role,
    required String actorUserId,
    required String visitId,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<void> unlockVisit({
    required Role role,
    required String actorUserId,
    required String visitId,
    required String reason,
  }) => throw UnimplementedError('not exercised by this test');
}

class _FakePatientRepository implements PatientRepository {
  _FakePatientRepository(this._patients);

  final List<PatientRecord> _patients;
  final List<PatientRecord> created = <PatientRecord>[];

  @override
  Stream<List<PatientRecord>> watchAll({
    required Role role,
    String query = '',
  }) {
    if (query.trim().isEmpty) return Stream.value(_patients);
    final String needle = query.trim().toLowerCase();
    final List<PatientRecord> filtered = _patients
        .where(
          (PatientRecord p) =>
              p.firstName.toLowerCase().contains(needle) ||
              p.lastName.toLowerCase().contains(needle),
        )
        .toList();
    return Stream.value(filtered);
  }

  @override
  Future<void> create({
    required Role role,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String phone,
    String? email,
    String? historyNotes,
  }) async {
    created.add(
      PatientRecord(
        id: 'new-${created.length}',
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        phone: phone,
        email: email,
        historyNotes: historyNotes,
      ),
    );
  }

  final List<PatientRecord> updated = <PatientRecord>[];

  @override
  Future<void> updatePatient({
    required Role role,
    required String actorUserId,
    required String patientId,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String phone,
    String? email,
    String? historyNotes,
  }) async {
    updated.add(
      PatientRecord(
        id: patientId,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        phone: phone,
        email: email,
        historyNotes: historyNotes,
      ),
    );
  }

  final List<String> deleted = <String>[];

  @override
  Future<void> deletePatient({
    required Role role,
    required String patientId,
  }) async {
    deleted.add(patientId);
  }
}

Future<ProviderContainer> _pumpPage(
  WidgetTester tester,
  _FakePatientRepository fakeRepository, {
  List<VisitRecord> visits = const <VisitRecord>[],
}) async {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      patientRepositoryProvider.overrideWithValue(fakeRepository),
      appointmentRepositoryProvider.overrideWithValue(
        _FakeAppointmentRepository(),
      ),
      visitRepositoryProvider.overrideWithValue(
        _FakeVisitRepository(visits: visits),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(currentRoleProvider.notifier).setRole(Role.assistant);
  container.read(currentUserIdProvider.notifier).setUserId('actor-1');

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PatientListPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  final List<PatientRecord> seedPatients = <PatientRecord>[
    PatientRecord(
      id: '1',
      firstName: 'Amine',
      lastName: 'Trabelsi',
      dateOfBirth: DateTime(1990, 5, 12),
      phone: '20123456',
    ),
    PatientRecord(
      id: '2',
      firstName: 'Sarra',
      lastName: 'Ben Youssef',
      dateOfBirth: DateTime(1985, 2, 3),
      phone: '99887766',
    ),
  ];

  testWidgets('renders patients from the repository', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, _FakePatientRepository(seedPatients));

    expect(find.text('Amine Trabelsi'), findsOneWidget);
    expect(find.text('Sarra Ben Youssef'), findsOneWidget);
  });

  testWidgets('typing in search narrows the list', (WidgetTester tester) async {
    await _pumpPage(tester, _FakePatientRepository(seedPatients));

    await tester.enterText(find.byType(TextField).first, 'tra');
    await tester.pumpAndSettle();

    expect(find.text('Amine Trabelsi'), findsOneWidget);
    expect(find.text('Sarra Ben Youssef'), findsNothing);
  });

  testWidgets('selecting a row shows patient details', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, _FakePatientRepository(seedPatients));

    await tester.tap(find.text('Amine Trabelsi'));
    await tester.pumpAndSettle();

    expect(find.text('20123456'), findsWidgets);
  });

  testWidgets('Add patient dialog validates required fields', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, _FakePatientRepository(seedPatients));

    await tester.tap(find.text('Add patient'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsWidgets);
  });

  testWidgets('editing a patient pre-fills the form and submits the update', (
    WidgetTester tester,
  ) async {
    final _FakePatientRepository fakeRepository = _FakePatientRepository(
      seedPatients,
    );
    await _pumpPage(tester, fakeRepository);

    await tester.tap(find.text('Amine Trabelsi'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Edit patient'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Amine'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Trabelsi'),
      'Ben Salah',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fakeRepository.updated.length, 1);
    expect(fakeRepository.updated.first.id, '1');
    expect(fakeRepository.updated.first.lastName, 'Ben Salah');
  });

  testWidgets('doctor can confirm deleting the selected patient', (
    WidgetTester tester,
  ) async {
    final _FakePatientRepository fakeRepository = _FakePatientRepository(
      seedPatients,
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [patientRepositoryProvider.overrideWithValue(fakeRepository)],
    );
    addTearDown(container.dispose);
    container.read(currentRoleProvider.notifier).setRole(Role.doctor);
    container.read(currentUserIdProvider.notifier).setUserId('actor-1');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PatientListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Amine Trabelsi'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete this patient?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(fakeRepository.deleted, <String>['1']);
  });

  testWidgets('assistant does not see the delete control', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, _FakePatientRepository(seedPatients));

    await tester.tap(find.text('Amine Trabelsi'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('shows the patient\'s recent visits when they exist', (
    WidgetTester tester,
  ) async {
    final DateTime visitTime = DateTime(2026, 6, 8, 9, 30);
    await _pumpPage(
      tester,
      _FakePatientRepository(seedPatients),
      visits: <VisitRecord>[
        VisitRecord(
          id: 'v1',
          appointmentId: 'a1',
          patientId: '1',
          dentistId: 'dentist-1',
          status: VisitStatus.checkedIn,
          startedAt: visitTime,
        ),
      ],
    );

    await tester.tap(find.text('Amine Trabelsi'));
    await tester.pumpAndSettle();

    expect(find.textContaining('08/06/2026 09:30'), findsOneWidget);
    expect(find.textContaining('Checked in'), findsWidgets);
    expect(find.text('No visits yet'), findsNothing);
  });

  testWidgets('shows the empty state when the patient has no visits', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, _FakePatientRepository(seedPatients));

    await tester.tap(find.text('Amine Trabelsi'));
    await tester.pumpAndSettle();

    expect(find.text('No visits yet'), findsOneWidget);
  });
}
