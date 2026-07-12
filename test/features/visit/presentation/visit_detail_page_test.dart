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
import 'package:docentral/features/treatment_plan/domain/planned_treatment.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment_exceptions.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment_status.dart';
import 'package:docentral/features/visit/domain/performed_treatment.dart';
import 'package:docentral/features/visit/domain/performed_treatment_repository.dart';
import 'package:docentral/features/visit/domain/visit_exceptions.dart';
import 'package:docentral/features/visit/domain/visit_record.dart';
import 'package:docentral/features/visit/domain/visit_repository.dart';
import 'package:docentral/features/visit/domain/visit_status.dart';
import 'package:docentral/features/visit/presentation/providers/performed_treatment_repository_provider.dart';
import 'package:docentral/features/visit/presentation/providers/visit_repository_provider.dart';
import 'package:docentral/features/visit/presentation/visit_detail_page.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/current_user_id_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeVisitRepository implements VisitRepository {
  _FakeVisitRepository(this._visit);

  VisitRecord? _visit;
  final List<(String?, String?)> savedClinicalRecords = <(String?, String?)>[];
  final List<String> completedVisitIds = <String>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Future<String> checkIn({required Role role, required String appointmentId}) =>
      throw UnimplementedError('not exercised by this test');

  @override
  Stream<List<VisitRecord>> watchRecentVisits({
    required Role role,
    required String patientId,
    int limit = 3,
  }) => Stream.value(const <VisitRecord>[]);

  @override
  Stream<VisitRecord?> watchVisitForAppointment({
    required Role role,
    required String appointmentId,
  }) async* {
    yield _visit;
    await for (final _ in _changes.stream) {
      yield _visit;
    }
  }

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
  }) async {
    savedClinicalRecords.add((diagnosis, clinicalNotes));
  }

  @override
  Future<String> completeVisit({
    required Role role,
    required String actorUserId,
    required String visitId,
  }) async {
    completedVisitIds.add(visitId);
    final VisitRecord? existing = _visit;
    if (existing != null) {
      _visit = VisitRecord(
        id: existing.id,
        appointmentId: existing.appointmentId,
        patientId: existing.patientId,
        dentistId: existing.dentistId,
        status: VisitStatus.completed,
        startedAt: existing.startedAt,
        inProgressAt: existing.inProgressAt,
        diagnosis: existing.diagnosis,
        clinicalNotes: existing.clinicalNotes,
        endedAt: DateTime.now(),
      );
    }
    _changes.add(null);
    return 'invoice-1';
  }

  final List<String> unlockedVisitIds = <String>[];
  final List<String> unlockReasons = <String>[];
  Object? unlockErrorToThrow;

  @override
  Future<void> unlockVisit({
    required Role role,
    required String actorUserId,
    required String visitId,
    required String reason,
  }) async {
    if (unlockErrorToThrow != null) {
      throw unlockErrorToThrow!;
    }
    unlockedVisitIds.add(visitId);
    unlockReasons.add(reason);
    final VisitRecord? existing = _visit;
    if (existing != null) {
      _visit = VisitRecord(
        id: existing.id,
        appointmentId: existing.appointmentId,
        patientId: existing.patientId,
        dentistId: existing.dentistId,
        status: VisitStatus.inProgress,
        startedAt: existing.startedAt,
        inProgressAt: existing.inProgressAt,
        diagnosis: existing.diagnosis,
        clinicalNotes: existing.clinicalNotes,
      );
    }
    _changes.add(null);
  }
}

class _FakePerformedTreatmentRepository
    implements PerformedTreatmentRepository {
  _FakePerformedTreatmentRepository(List<PerformedTreatment> treatments)
    : _treatments = List<PerformedTreatment>.of(treatments);

  final List<PerformedTreatment> _treatments;
  final List<PerformedTreatment> added = <PerformedTreatment>[];
  final List<String> removed = <String>[];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<List<PerformedTreatment>> watchForVisit({
    required Role role,
    required String visitId,
  }) async* {
    yield List<PerformedTreatment>.of(_treatments);
    await for (final _ in _changes.stream) {
      yield List<PerformedTreatment>.of(_treatments);
    }
  }

  @override
  Future<String> addTreatment({
    required Role role,
    required String actorUserId,
    required String visitId,
    required String toothNumber,
    required String procedureName,
    required double unitPrice,
    required int quantity,
  }) async {
    final String id = 'treatment-${_treatments.length}';
    final PerformedTreatment treatment = PerformedTreatment(
      id: id,
      visitId: visitId,
      toothNumber: toothNumber,
      procedureName: procedureName,
      unitPrice: unitPrice,
      quantity: quantity,
      recordedByUserId: actorUserId,
      recordedAt: DateTime.now(),
    );
    _treatments.add(treatment);
    added.add(treatment);
    _changes.add(null);
    return id;
  }

  @override
  Future<void> updateTreatment({
    required Role role,
    required String treatmentId,
    required String toothNumber,
    required String procedureName,
    required double unitPrice,
    required int quantity,
  }) async {
    final int index = _treatments.indexWhere(
      (PerformedTreatment t) => t.id == treatmentId,
    );
    final PerformedTreatment existing = _treatments[index];
    _treatments[index] = PerformedTreatment(
      id: existing.id,
      visitId: existing.visitId,
      toothNumber: toothNumber,
      procedureName: procedureName,
      unitPrice: unitPrice,
      quantity: quantity,
      recordedByUserId: existing.recordedByUserId,
      recordedAt: existing.recordedAt,
    );
    _changes.add(null);
  }

  @override
  Future<void> removeTreatment({
    required Role role,
    required String treatmentId,
  }) async {
    removed.add(treatmentId);
    _treatments.removeWhere((PerformedTreatment t) => t.id == treatmentId);
    _changes.add(null);
  }

  final List<String> markedPerformedPlannedTreatmentIds = <String>[];
  Object? markPerformedErrorToThrow;

  @override
  Future<String> markPlannedTreatmentPerformed({
    required Role role,
    required String actorUserId,
    required String visitId,
    required String plannedTreatmentId,
  }) async {
    if (markPerformedErrorToThrow != null) {
      throw markPerformedErrorToThrow!;
    }
    markedPerformedPlannedTreatmentIds.add(plannedTreatmentId);
    final String id = 'treatment-${_treatments.length}';
    final PerformedTreatment treatment = PerformedTreatment(
      id: id,
      visitId: visitId,
      toothNumber: '14',
      procedureName: 'Root canal',
      unitPrice: 250,
      quantity: 1,
      recordedByUserId: actorUserId,
      recordedAt: DateTime.now(),
    );
    _treatments.add(treatment);
    added.add(treatment);
    _changes.add(null);
    return id;
  }
}

class _FakeAppointmentRepository implements AppointmentRepository {
  _FakeAppointmentRepository([
    Map<String, PlannedTreatment> plannedTreatmentsById =
        const <String, PlannedTreatment>{},
  ]) : _plannedTreatmentsById = plannedTreatmentsById;

  final Map<String, PlannedTreatment> _plannedTreatmentsById;

  @override
  Stream<List<PlannedTreatment>> watchLinkedPlannedTreatments({
    required Role role,
    required String appointmentId,
  }) => Stream.value(_plannedTreatmentsById.values.toList());

  @override
  Stream<List<AppointmentRecord>> watchToday({required Role role}) =>
      throw UnimplementedError('not exercised by this test');

  @override
  Stream<List<AppointmentRecord>> watchRange({
    required Role role,
    required DateTime start,
    required DateTime end,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Stream<List<AssignableUser>> watchAssignableUsers({required Role role}) =>
      throw UnimplementedError('not exercised by this test');

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
  }) => throw UnimplementedError('not exercised by this test');
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

Future<
  ({_FakeVisitRepository visit, _FakePerformedTreatmentRepository treatments})
>
_pumpPage(
  WidgetTester tester, {
  required VisitRecord? visit,
  List<PerformedTreatment> treatments = const <PerformedTreatment>[],
  List<PlannedTreatment> linkedPlannedTreatments = const <PlannedTreatment>[],
  Role role = Role.assistant,
}) async {
  final _FakePerformedTreatmentRepository fakeTreatmentRepository =
      _FakePerformedTreatmentRepository(treatments);
  addTearDown(() => fakeTreatmentRepository._changes.close());
  final _FakeVisitRepository fakeVisitRepository = _FakeVisitRepository(visit);

  final ProviderContainer container = ProviderContainer(
    overrides: [
      visitRepositoryProvider.overrideWithValue(fakeVisitRepository),
      performedTreatmentRepositoryProvider.overrideWithValue(
        fakeTreatmentRepository,
      ),
      appointmentRepositoryProvider.overrideWithValue(
        _FakeAppointmentRepository(<String, PlannedTreatment>{
          for (final PlannedTreatment t in linkedPlannedTreatments) t.id: t,
        }),
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
        home: VisitDetailPage(
          appointmentId: 'appointment-1',
          patientName: 'Amine Trabelsi',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (visit: fakeVisitRepository, treatments: fakeTreatmentRepository);
}

void main() {
  final VisitRecord inProgressVisit = VisitRecord(
    id: 'visit-1',
    appointmentId: 'appointment-1',
    patientId: 'p1',
    dentistId: 'dentist-1',
    status: VisitStatus.inProgress,
    startedAt: DateTime.now(),
  );

  testWidgets('shows the empty state when there are no treatments', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, visit: inProgressVisit);

    expect(find.text('No treatments recorded yet'), findsOneWidget);
  });

  testWidgets(
    'renders performed treatments with tooth number and total price',
    (WidgetTester tester) async {
      await _pumpPage(
        tester,
        visit: inProgressVisit,
        treatments: <PerformedTreatment>[
          PerformedTreatment(
            id: 't1',
            visitId: 'visit-1',
            toothNumber: '18',
            procedureName: 'Filling',
            unitPrice: 50,
            quantity: 2,
            recordedByUserId: 'actor-1',
            recordedAt: DateTime.now(),
          ),
        ],
      );

      expect(find.text('Filling'), findsOneWidget);
      expect(find.textContaining('18'), findsWidgets);
    },
  );

  testWidgets('adding a treatment saves it and updates the list', (
    WidgetTester tester,
  ) async {
    final fakeRepository = (await _pumpPage(
      tester,
      visit: inProgressVisit,
    )).treatments;

    await tester.tap(find.text('Add treatment'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tooth number'),
      '18',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Procedure'),
      'Filling',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Unit price'),
      '50',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '1');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fakeRepository.added.length, 1);
    expect(fakeRepository.added.single.toothNumber, '18');
    expect(fakeRepository.added.single.recordedByUserId, 'actor-1');
    expect(find.text('Filling'), findsOneWidget);
  });

  testWidgets('removing a treatment deletes it from the list', (
    WidgetTester tester,
  ) async {
    final fakeRepository = (await _pumpPage(
      tester,
      visit: inProgressVisit,
      treatments: <PerformedTreatment>[
        PerformedTreatment(
          id: 't1',
          visitId: 'visit-1',
          toothNumber: '18',
          procedureName: 'Filling',
          unitPrice: 50,
          quantity: 1,
          recordedByUserId: 'actor-1',
          recordedAt: DateTime.now(),
        ),
      ],
    )).treatments;

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(fakeRepository.removed, <String>['t1']);
    expect(find.text('Filling'), findsNothing);
  });

  testWidgets(
    'edit/remove controls and Add treatment are hidden on a completed visit',
    (WidgetTester tester) async {
      final VisitRecord completedVisit = VisitRecord(
        id: 'visit-1',
        appointmentId: 'appointment-1',
        patientId: 'p1',
        dentistId: 'dentist-1',
        status: VisitStatus.completed,
        startedAt: DateTime.now(),
      );

      await _pumpPage(
        tester,
        visit: completedVisit,
        treatments: <PerformedTreatment>[
          PerformedTreatment(
            id: 't1',
            visitId: 'visit-1',
            toothNumber: '18',
            procedureName: 'Filling',
            unitPrice: 50,
            quantity: 1,
            recordedByUserId: 'actor-1',
            recordedAt: DateTime.now(),
          ),
        ],
      );

      expect(find.text('Add treatment'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    },
  );

  testWidgets(
    'editing diagnosis autosaves on blur without an explicit save button',
    (WidgetTester tester) async {
      final fakeVisitRepository = (await _pumpPage(
        tester,
        visit: inProgressVisit,
      )).visit;

      await tester.enterText(
        find.widgetWithText(TextField, 'Diagnosis'),
        'Cavity on tooth 18',
      );
      // Move focus elsewhere to trigger blur.
      await tester.tap(find.widgetWithText(TextField, 'Clinical notes'));
      await tester.pumpAndSettle();
      // Blur the notes field too so its own autosave fires deterministically.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      expect(fakeVisitRepository.savedClinicalRecords, isNotEmpty);
      expect(
        fakeVisitRepository.savedClinicalRecords.any(
          (record) => record.$1 == 'Cavity on tooth 18',
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'diagnosis and clinical notes are read-only on a completed visit',
    (WidgetTester tester) async {
      final VisitRecord completedVisit = VisitRecord(
        id: 'visit-1',
        appointmentId: 'appointment-1',
        patientId: 'p1',
        dentistId: 'dentist-1',
        status: VisitStatus.completed,
        startedAt: DateTime.now(),
        diagnosis: 'Cavity',
        clinicalNotes: 'Patient tolerated well',
      );

      await _pumpPage(tester, visit: completedVisit);

      final TextField diagnosisField = tester.widget(
        find.widgetWithText(TextField, 'Diagnosis'),
      );
      expect(diagnosisField.readOnly, isTrue);
      expect(find.text('Cavity'), findsOneWidget);
      expect(find.text('Patient tolerated well'), findsOneWidget);
    },
  );

  testWidgets(
    'Complete visit button is hidden when there are no treatments yet',
    (WidgetTester tester) async {
      await _pumpPage(tester, visit: inProgressVisit);

      expect(find.text('Complete visit'), findsNothing);
    },
  );

  testWidgets('Complete visit button is hidden on an already-completed visit', (
    WidgetTester tester,
  ) async {
    final VisitRecord completedVisit = VisitRecord(
      id: 'visit-1',
      appointmentId: 'appointment-1',
      patientId: 'p1',
      dentistId: 'dentist-1',
      status: VisitStatus.completed,
      startedAt: DateTime.now(),
    );

    await _pumpPage(
      tester,
      visit: completedVisit,
      treatments: <PerformedTreatment>[
        PerformedTreatment(
          id: 't1',
          visitId: 'visit-1',
          toothNumber: '18',
          procedureName: 'Filling',
          unitPrice: 50,
          quantity: 1,
          recordedByUserId: 'actor-1',
          recordedAt: DateTime.now(),
        ),
      ],
    );

    expect(find.text('Complete visit'), findsNothing);
  });

  testWidgets('completing a visit shows a confirmation dialog', (
    WidgetTester tester,
  ) async {
    final fakeVisitRepository = (await _pumpPage(
      tester,
      visit: inProgressVisit,
      treatments: <PerformedTreatment>[
        PerformedTreatment(
          id: 't1',
          visitId: 'visit-1',
          toothNumber: '18',
          procedureName: 'Filling',
          unitPrice: 50,
          quantity: 1,
          recordedByUserId: 'actor-1',
          recordedAt: DateTime.now(),
        ),
      ],
    )).visit;

    await tester.tap(find.text('Complete visit'));
    await tester.pumpAndSettle();

    expect(find.text('Complete this visit?'), findsOneWidget);

    // Cancelling must not call completeVisit.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fakeVisitRepository.completedVisitIds, isEmpty);
  });

  testWidgets(
    'confirming Complete visit calls completeVisit and shows a success snackbar',
    (WidgetTester tester) async {
      final fakeVisitRepository = (await _pumpPage(
        tester,
        visit: inProgressVisit,
        treatments: <PerformedTreatment>[
          PerformedTreatment(
            id: 't1',
            visitId: 'visit-1',
            toothNumber: '18',
            procedureName: 'Filling',
            unitPrice: 50,
            quantity: 1,
            recordedByUserId: 'actor-1',
            recordedAt: DateTime.now(),
          ),
        ],
      )).visit;

      await tester.tap(find.text('Complete visit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      // Avoid pumpAndSettle here: it would advance time past the SnackBar's
      // auto-dismiss duration before we get a chance to assert on it.
      await tester.pump(); // dialog pop animation starts + completeVisit begins
      await tester.pump(const Duration(milliseconds: 300)); // dialog closed
      await tester.pump(); // completeVisit future resolves, snackbar shown
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // snackbar animates in

      expect(fakeVisitRepository.completedVisitIds, <String>['visit-1']);
      expect(
        find.text('Visit completed. A draft invoice was created.'),
        findsOneWidget,
      );
      // The button disappears once the visit transitions to completed.
      expect(find.text('Complete visit'), findsNothing);
    },
  );

  VisitRecord completedVisit() => VisitRecord(
    id: 'visit-1',
    appointmentId: 'appointment-1',
    patientId: 'p1',
    dentistId: 'dentist-1',
    status: VisitStatus.completed,
    startedAt: DateTime.now(),
    endedAt: DateTime.now(),
  );

  testWidgets('Unlock visit button is hidden for a non-doctor role', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, visit: completedVisit(), role: Role.assistant);

    expect(find.text('Unlock visit'), findsNothing);
  });

  testWidgets('Unlock visit button is hidden when the visit is not completed', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, visit: inProgressVisit, role: Role.doctor);

    expect(find.text('Unlock visit'), findsNothing);
  });

  testWidgets('cancelling the unlock dialog does not call unlockVisit', (
    WidgetTester tester,
  ) async {
    final fakeVisitRepository = (await _pumpPage(
      tester,
      visit: completedVisit(),
      role: Role.doctor,
    )).visit;

    await tester.tap(find.text('Unlock visit'));
    await tester.pumpAndSettle();

    expect(find.text('Unlock this visit?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fakeVisitRepository.unlockedVisitIds, isEmpty);
  });

  testWidgets('confirming with a blank reason shows a validation error', (
    WidgetTester tester,
  ) async {
    final fakeVisitRepository = (await _pumpPage(
      tester,
      visit: completedVisit(),
      role: Role.doctor,
    )).visit;

    await tester.tap(find.text('Unlock visit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(
      find.text('A reason is required to unlock this visit.'),
      findsOneWidget,
    );
    expect(fakeVisitRepository.unlockedVisitIds, isEmpty);
  });

  testWidgets(
    'confirming Unlock visit with a reason calls unlockVisit and shows a '
    'success snackbar',
    (WidgetTester tester) async {
      final fakeVisitRepository = (await _pumpPage(
        tester,
        visit: completedVisit(),
        role: Role.doctor,
      )).visit;

      await tester.tap(find.text('Unlock visit'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Reason'),
        'Wrong tooth number recorded',
      );
      await tester.tap(find.text('Confirm'));
      // Avoid pumpAndSettle: it would advance past the SnackBar's dismiss.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeVisitRepository.unlockedVisitIds, <String>['visit-1']);
      expect(fakeVisitRepository.unlockReasons, <String>[
        'Wrong tooth number recorded',
      ]);
      expect(find.text('Visit unlocked.'), findsOneWidget);
      expect(find.text('Unlock visit'), findsNothing);
    },
  );

  testWidgets('shows a specific error when the invoice has payments recorded', (
    WidgetTester tester,
  ) async {
    final fakeVisitRepository = (await _pumpPage(
      tester,
      visit: completedVisit(),
      role: Role.doctor,
    )).visit;
    fakeVisitRepository.unlockErrorToThrow =
        const VisitInvoiceHasPaymentsException();

    await tester.tap(find.text('Unlock visit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason'),
      'Test reason',
    );
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text(
        'This invoice has payments recorded. Void it before unlocking the visit.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows a specific error when the invoice has been voided', (
    WidgetTester tester,
  ) async {
    final fakeVisitRepository = (await _pumpPage(
      tester,
      visit: completedVisit(),
      role: Role.doctor,
    )).visit;
    fakeVisitRepository.unlockErrorToThrow =
        const VisitInvoiceFinalizedException();

    await tester.tap(find.text('Unlock visit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Reason'),
      'Test reason',
    );
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('This invoice has been voided and can no longer be unlocked.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows linked planned treatments awaiting performance with a Mark performed button',
    (WidgetTester tester) async {
      await _pumpPage(
        tester,
        visit: inProgressVisit,
        linkedPlannedTreatments: const <PlannedTreatment>[
          PlannedTreatment(
            id: 'pt1',
            patientId: 'p1',
            procedureName: 'Root canal',
            toothNumber: '14',
            estimatedUnitPrice: 250,
            sequenceNumber: 1,
            status: PlannedTreatmentStatus.scheduled,
          ),
        ],
      );

      expect(find.text('Planned treatments for this visit'), findsOneWidget);
      expect(find.textContaining('Root canal'), findsOneWidget);
      expect(find.text('Mark performed'), findsOneWidget);
    },
  );

  testWidgets(
    'a linked planned treatment that is not scheduled is not offered for marking performed',
    (WidgetTester tester) async {
      await _pumpPage(
        tester,
        visit: inProgressVisit,
        linkedPlannedTreatments: const <PlannedTreatment>[
          PlannedTreatment(
            id: 'pt1',
            patientId: 'p1',
            procedureName: 'Root canal',
            toothNumber: '14',
            estimatedUnitPrice: 250,
            sequenceNumber: 1,
            status: PlannedTreatmentStatus.done,
          ),
        ],
      );

      expect(find.text('Planned treatments for this visit'), findsNothing);
      expect(find.text('Mark performed'), findsNothing);
    },
  );

  testWidgets(
    'tapping Mark performed creates a matching Performed Treatment and removes the row',
    (WidgetTester tester) async {
      final result = await _pumpPage(
        tester,
        visit: inProgressVisit,
        linkedPlannedTreatments: const <PlannedTreatment>[
          PlannedTreatment(
            id: 'pt1',
            patientId: 'p1',
            procedureName: 'Root canal',
            toothNumber: '14',
            estimatedUnitPrice: 250,
            sequenceNumber: 1,
            status: PlannedTreatmentStatus.scheduled,
          ),
        ],
      );

      await tester.tap(find.text('Mark performed'));
      await tester.pumpAndSettle();

      expect(result.treatments.markedPerformedPlannedTreatmentIds, <String>[
        'pt1',
      ]);
      expect(result.treatments.added.single.toothNumber, '14');
      expect(result.treatments.added.single.procedureName, 'Root canal');
      expect(result.treatments.added.single.unitPrice, 250);
      expect(result.treatments.added.single.quantity, 1);
    },
  );

  testWidgets('the planned-treatments section is hidden on a completed visit', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      visit: completedVisit(),
      role: Role.doctor,
      linkedPlannedTreatments: const <PlannedTreatment>[
        PlannedTreatment(
          id: 'pt1',
          patientId: 'p1',
          procedureName: 'Root canal',
          toothNumber: '14',
          estimatedUnitPrice: 250,
          sequenceNumber: 1,
          status: PlannedTreatmentStatus.scheduled,
        ),
      ],
    );

    expect(find.text('Planned treatments for this visit'), findsNothing);
  });

  testWidgets(
    'shows an error when marking performed fails because the planned treatment is no longer scheduled',
    (WidgetTester tester) async {
      final result = await _pumpPage(
        tester,
        visit: inProgressVisit,
        linkedPlannedTreatments: const <PlannedTreatment>[
          PlannedTreatment(
            id: 'pt1',
            patientId: 'p1',
            procedureName: 'Root canal',
            toothNumber: '14',
            estimatedUnitPrice: 250,
            sequenceNumber: 1,
            status: PlannedTreatmentStatus.scheduled,
          ),
        ],
      );
      result.treatments.markPerformedErrorToThrow =
          const PlannedTreatmentNotScheduledException();

      await tester.tap(find.text('Mark performed'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text(
          'This planned treatment is no longer scheduled for this visit.',
        ),
        findsOneWidget,
      );
    },
  );
}
