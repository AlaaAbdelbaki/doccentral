import 'dart:async';

import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_repository.dart';
import 'package:docentral/features/appointment/domain/assignable_user.dart';
import 'package:docentral/features/appointment/domain/cancellation_reason.dart';
import 'package:docentral/features/appointment/presentation/providers/appointment_repository_provider.dart';
import 'package:docentral/features/attachment/domain/attachment.dart';
import 'package:docentral/features/attachment/domain/attachment_repository.dart';
import 'package:docentral/features/attachment/domain/attachment_target_type.dart';
import 'package:docentral/features/attachment/presentation/providers/attachment_repository_provider.dart';
import 'package:docentral/features/invoice/domain/invoice_adjustment_type.dart';
import 'package:docentral/features/invoice/domain/invoice_item.dart';
import 'package:docentral/features/invoice/domain/invoice_record.dart';
import 'package:docentral/features/invoice/domain/invoice_repository.dart';
import 'package:docentral/features/invoice/domain/patient_balance.dart';
import 'package:docentral/features/invoice/presentation/providers/invoice_repository_provider.dart';
import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:docentral/features/patient/domain/patient_repository.dart';
import 'package:docentral/features/patient/presentation/patient_list_page.dart';
import 'package:docentral/features/patient/presentation/providers/patient_repository_provider.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment_repository.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment_status.dart';
import 'package:docentral/features/treatment_plan/presentation/providers/planned_treatment_repository_provider.dart';
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

class _FakeInvoiceRepository implements InvoiceRepository {
  @override
  Stream<InvoiceRecord?> watchInvoiceForVisit({
    required Role role,
    required String visitId,
  }) => Stream.value(null);

  @override
  Stream<List<InvoiceItem>> watchItemsForInvoice({
    required Role role,
    required String invoiceId,
  }) => Stream.value(const <InvoiceItem>[]);

  @override
  Future<String> addAdjustment({
    required Role role,
    required String invoiceId,
    required InvoiceAdjustmentType adjustmentType,
    required String description,
    required double amount,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<void> finalizeInvoice({
    required Role role,
    required String actorUserId,
    required String invoiceId,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<void> voidInvoice({
    required Role role,
    required String actorUserId,
    required String invoiceId,
    required String reason,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Stream<double> watchOutstandingBalanceForPatient({
    required Role role,
    required String patientId,
  }) => Stream.value(0);

  @override
  Stream<List<PatientBalance>> watchPatientsWithBalance({required Role role}) =>
      Stream.value(const <PatientBalance>[]);
}

class _FakePlannedTreatmentRepository implements PlannedTreatmentRepository {
  _FakePlannedTreatmentRepository([
    List<PlannedTreatment> treatments = const [],
  ]) : _treatments = List<PlannedTreatment>.of(treatments);

  final List<PlannedTreatment> _treatments;
  final List<PlannedTreatment> added = <PlannedTreatment>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<List<PlannedTreatment>> watchForPatient({
    required Role role,
    required String patientId,
  }) async* {
    yield List<PlannedTreatment>.of(_treatments);
    await for (final _ in _changes.stream) {
      yield List<PlannedTreatment>.of(_treatments);
    }
  }

  @override
  Future<String> addPlannedTreatment({
    required Role role,
    required String patientId,
    required String procedureName,
    required String toothNumber,
    required double estimatedUnitPrice,
    DateTime? targetDate,
  }) async {
    final String id = 'planned-${_treatments.length}';
    final PlannedTreatment treatment = PlannedTreatment(
      id: id,
      patientId: patientId,
      procedureName: procedureName,
      toothNumber: toothNumber,
      estimatedUnitPrice: estimatedUnitPrice,
      sequenceNumber: _treatments.length + 1,
      status: PlannedTreatmentStatus.planned,
      targetDate: targetDate,
    );
    _treatments.add(treatment);
    added.add(treatment);
    _changes.add(null);
    return id;
  }
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

class _FakeAttachmentRepository implements AttachmentRepository {
  @override
  Future<String> upload({
    required Role role,
    required String actorUserId,
    required AttachmentTargetType targetType,
    required String targetId,
    required String sourceFilePath,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Stream<List<Attachment>> watchForTarget({
    required Role role,
    required AttachmentTargetType targetType,
    required String targetId,
  }) => Stream.value(const <Attachment>[]);
}

Future<ProviderContainer> _pumpPage(
  WidgetTester tester,
  _FakePatientRepository fakeRepository, {
  List<VisitRecord> visits = const <VisitRecord>[],
  _FakePlannedTreatmentRepository? plannedTreatments,
  Role role = Role.assistant,
}) async {
  final _FakePlannedTreatmentRepository fakePlannedTreatments =
      plannedTreatments ?? _FakePlannedTreatmentRepository();
  addTearDown(() => fakePlannedTreatments._changes.close());
  final ProviderContainer container = ProviderContainer(
    overrides: [
      patientRepositoryProvider.overrideWithValue(fakeRepository),
      appointmentRepositoryProvider.overrideWithValue(
        _FakeAppointmentRepository(),
      ),
      visitRepositoryProvider.overrideWithValue(
        _FakeVisitRepository(visits: visits),
      ),
      invoiceRepositoryProvider.overrideWithValue(_FakeInvoiceRepository()),
      plannedTreatmentRepositoryProvider.overrideWithValue(
        fakePlannedTreatments,
      ),
      attachmentRepositoryProvider.overrideWithValue(
        _FakeAttachmentRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(currentRoleProvider.notifier).setRole(role);
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
      overrides: [
        patientRepositoryProvider.overrideWithValue(fakeRepository),
        invoiceRepositoryProvider.overrideWithValue(_FakeInvoiceRepository()),
        plannedTreatmentRepositoryProvider.overrideWithValue(
          _FakePlannedTreatmentRepository(),
        ),
        attachmentRepositoryProvider.overrideWithValue(
          _FakeAttachmentRepository(),
        ),
      ],
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

  testWidgets('shows the empty state when there is no treatment plan yet', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, _FakePatientRepository(seedPatients));

    await tester.tap(find.text('Amine Trabelsi'));
    await tester.pumpAndSettle();

    expect(find.text('No planned treatments yet'), findsOneWidget);
  });

  testWidgets('shows planned treatments in sequence order', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      _FakePatientRepository(seedPatients),
      plannedTreatments: _FakePlannedTreatmentRepository(<PlannedTreatment>[
        const PlannedTreatment(
          id: 'pt1',
          patientId: '1',
          procedureName: 'Filling',
          toothNumber: '18',
          estimatedUnitPrice: 50,
          sequenceNumber: 1,
          status: PlannedTreatmentStatus.planned,
        ),
      ]),
    );

    await tester.tap(find.text('Amine Trabelsi'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Filling'), findsOneWidget);
    expect(find.textContaining('Next available'), findsOneWidget);
    expect(find.text('Planned'), findsOneWidget);
  });

  testWidgets('Add planned treatment button is hidden for an Assistant', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, _FakePatientRepository(seedPatients));

    await tester.tap(find.text('Amine Trabelsi'));
    await tester.pumpAndSettle();

    expect(find.text('Add planned treatment'), findsNothing);
  });

  testWidgets(
    'a doctor can add a planned treatment and it appears in the list',
    (WidgetTester tester) async {
      final _FakePlannedTreatmentRepository fakePlannedTreatments =
          _FakePlannedTreatmentRepository();
      await _pumpPage(
        tester,
        _FakePatientRepository(seedPatients),
        plannedTreatments: fakePlannedTreatments,
        role: Role.doctor,
      );

      await tester.tap(find.text('Amine Trabelsi'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add planned treatment'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Procedure'),
        'Root canal',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tooth number'),
        '14',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Estimated unit price'),
        '200',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fakePlannedTreatments.added.length, 1);
      expect(fakePlannedTreatments.added.single.procedureName, 'Root canal');
      expect(fakePlannedTreatments.added.single.toothNumber, '14');
      expect(fakePlannedTreatments.added.single.estimatedUnitPrice, 200);
      expect(find.textContaining('Root canal'), findsOneWidget);
    },
  );
}
