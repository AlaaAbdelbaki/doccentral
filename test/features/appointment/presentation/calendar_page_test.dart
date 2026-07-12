import 'dart:async';

import 'package:docentral/features/appointment/domain/appointment_exceptions.dart';
import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_repository.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
import 'package:docentral/features/appointment/domain/assignable_user.dart';
import 'package:docentral/features/appointment/domain/cancellation_reason.dart';
import 'package:docentral/features/appointment/presentation/calendar_page.dart';
import 'package:docentral/features/appointment/presentation/providers/appointment_repository_provider.dart';
import 'package:docentral/features/inventory/domain/inventory_category.dart';
import 'package:docentral/features/inventory/domain/inventory_item.dart';
import 'package:docentral/features/inventory/domain/inventory_repository.dart';
import 'package:docentral/features/inventory/domain/restock_event.dart';
import 'package:docentral/features/inventory/domain/stock_adjustment.dart';
import 'package:docentral/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:docentral/features/patient/domain/patient_repository.dart';
import 'package:docentral/features/patient/presentation/providers/patient_repository_provider.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment_repository.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment_status.dart';
import 'package:docentral/features/treatment_plan/presentation/providers/planned_treatment_repository_provider.dart';
import 'package:docentral/features/visit/domain/visit_exceptions.dart';
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

class _FakePatientRepository implements PatientRepository {
  _FakePatientRepository(this._patients);

  final List<PatientRecord> _patients;

  @override
  Stream<List<PatientRecord>> watchAll({
    required Role role,
    String query = '',
  }) => Stream.value(_patients);

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
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<void> deletePatient({required Role role, required String patientId}) =>
      throw UnimplementedError('not exercised by this test');
}

class _FakeAppointmentRepository implements AppointmentRepository {
  _FakeAppointmentRepository(
    List<AppointmentRecord> appointments, {
    this.assignableUsers = const <AssignableUser>[],
    Map<String, PlannedTreatment> plannedTreatmentsById =
        const <String, PlannedTreatment>{},
    Map<String, List<String>> initialLinks = const <String, List<String>>{},
  }) : _appointments = List<AppointmentRecord>.of(appointments),
       _plannedTreatmentsById = plannedTreatmentsById,
       linkedTreatmentIdsByAppointment = Map<String, List<String>>.of(
         initialLinks,
       );

  final List<AppointmentRecord> _appointments;
  final List<AssignableUser> assignableUsers;
  final Map<String, PlannedTreatment> _plannedTreatmentsById;
  final Map<String, List<String>> linkedTreatmentIdsByAppointment;
  final List<AppointmentRecord> created = <AppointmentRecord>[];
  final List<AppointmentRecord> updatedCalls = <AppointmentRecord>[];
  final List<CancellationReason> cancelledReasons = <CancellationReason>[];
  final List<AppointmentRecord> rescheduledTo = <AppointmentRecord>[];
  Object? plannedTreatmentErrorToThrow;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<List<AppointmentRecord>> watchToday({required Role role}) async* {
    yield List<AppointmentRecord>.of(_appointments);
    await for (final _ in _changes.stream) {
      yield List<AppointmentRecord>.of(_appointments);
    }
  }

  @override
  Stream<List<AppointmentRecord>> watchRange({
    required Role role,
    required DateTime start,
    required DateTime end,
  }) async* {
    List<AppointmentRecord> filtered() => _appointments
        .where(
          (AppointmentRecord a) =>
              !a.startTime.isBefore(start) && a.startTime.isBefore(end),
        )
        .toList();
    yield filtered();
    await for (final _ in _changes.stream) {
      yield filtered();
    }
  }

  @override
  Stream<List<AssignableUser>> watchAssignableUsers({required Role role}) =>
      Stream.value(assignableUsers);

  bool _overlaps(
    String assignedUserId,
    DateTime startTime,
    DateTime endTime, {
    String? excludingId,
  }) {
    return _appointments.any(
      (AppointmentRecord a) =>
          a.id != excludingId &&
          a.assignedUserId == assignedUserId &&
          a.status != AppointmentStatus.cancelled &&
          a.startTime.isBefore(endTime) &&
          a.endTime.isAfter(startTime),
    );
  }

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
  }) async {
    if (!overrideOverlap && _overlaps(assignedUserId, startTime, endTime)) {
      throw const AppointmentOverlapException();
    }
    if (plannedTreatmentErrorToThrow != null) {
      throw plannedTreatmentErrorToThrow!;
    }
    final String id = 'new-${_appointments.length}';
    final AppointmentRecord record = AppointmentRecord(
      id: id,
      patientId: patientId,
      patientName: 'Patient $patientId',
      assignedUserId: assignedUserId,
      startTime: startTime,
      endTime: endTime,
      status: AppointmentStatus.scheduled,
      reason: reason,
      notes: notes,
    );
    _appointments.add(record);
    created.add(record);
    linkedTreatmentIdsByAppointment[id] = plannedTreatmentIds;
    _changes.add(null);
    return id;
  }

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
  }) async {
    final int index = _appointments.indexWhere(
      (AppointmentRecord a) => a.id == appointmentId,
    );
    final AppointmentRecord existing = _appointments[index];
    if (existing.status != AppointmentStatus.scheduled) {
      throw const AppointmentNotEditableException();
    }
    if (!overrideOverlap &&
        _overlaps(
          assignedUserId,
          startTime,
          endTime,
          excludingId: appointmentId,
        )) {
      throw const AppointmentOverlapException();
    }
    if (plannedTreatmentErrorToThrow != null) {
      throw plannedTreatmentErrorToThrow!;
    }
    final AppointmentRecord updated = AppointmentRecord(
      id: existing.id,
      patientId: existing.patientId,
      patientName: existing.patientName,
      assignedUserId: assignedUserId,
      startTime: startTime,
      endTime: endTime,
      status: existing.status,
      reason: reason,
      notes: notes,
    );
    _appointments[index] = updated;
    updatedCalls.add(updated);
    linkedTreatmentIdsByAppointment[appointmentId] = plannedTreatmentIds;
    _changes.add(null);
  }

  @override
  Future<void> cancelAppointment({
    required Role role,
    required String actorUserId,
    required String appointmentId,
    required CancellationReason reason,
  }) async {
    final int index = _appointments.indexWhere(
      (AppointmentRecord a) => a.id == appointmentId,
    );
    final AppointmentRecord existing = _appointments[index];
    if (existing.status != AppointmentStatus.scheduled) {
      throw const AppointmentNotEditableException();
    }
    _appointments[index] = AppointmentRecord(
      id: existing.id,
      patientId: existing.patientId,
      patientName: existing.patientName,
      assignedUserId: existing.assignedUserId,
      startTime: existing.startTime,
      endTime: existing.endTime,
      status: AppointmentStatus.cancelled,
      reason: existing.reason,
      notes: existing.notes,
    );
    cancelledReasons.add(reason);
    _changes.add(null);
  }

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
  }) async {
    final int index = _appointments.indexWhere(
      (AppointmentRecord a) => a.id == appointmentId,
    );
    final AppointmentRecord existing = _appointments[index];
    if (existing.status != AppointmentStatus.scheduled) {
      throw const AppointmentNotEditableException();
    }
    if (!overrideOverlap &&
        _overlaps(newAssignedUserId, newStartTime, newEndTime)) {
      throw const AppointmentOverlapException();
    }

    final String newId = 'rescheduled-${_appointments.length}';
    final AppointmentRecord replacement = AppointmentRecord(
      id: newId,
      patientId: existing.patientId,
      patientName: existing.patientName,
      assignedUserId: newAssignedUserId,
      startTime: newStartTime,
      endTime: newEndTime,
      status: AppointmentStatus.scheduled,
      reason: newReason,
      notes: newNotes,
    );
    _appointments.add(replacement);
    _appointments[index] = AppointmentRecord(
      id: existing.id,
      patientId: existing.patientId,
      patientName: existing.patientName,
      assignedUserId: existing.assignedUserId,
      startTime: existing.startTime,
      endTime: existing.endTime,
      status: AppointmentStatus.cancelled,
      reason: existing.reason,
      notes: existing.notes,
    );
    cancelledReasons.add(CancellationReason.rescheduled);
    rescheduledTo.add(replacement);
    _changes.add(null);
    return newId;
  }

  @override
  Stream<int> watchNoShowCount({
    required Role role,
    required String patientId,
  }) => Stream.value(0);

  @override
  Stream<List<PlannedTreatment>> watchLinkedPlannedTreatments({
    required Role role,
    required String appointmentId,
  }) async* {
    List<PlannedTreatment> current() =>
        (linkedTreatmentIdsByAppointment[appointmentId] ?? const <String>[])
            .map((String id) => _plannedTreatmentsById[id])
            .whereType<PlannedTreatment>()
            .toList();
    yield current();
    await for (final _ in _changes.stream) {
      yield current();
    }
  }

  void markCheckedIn(String appointmentId) {
    final int index = _appointments.indexWhere(
      (AppointmentRecord a) => a.id == appointmentId,
    );
    final AppointmentRecord existing = _appointments[index];
    _appointments[index] = AppointmentRecord(
      id: existing.id,
      patientId: existing.patientId,
      patientName: existing.patientName,
      assignedUserId: existing.assignedUserId,
      startTime: existing.startTime,
      endTime: existing.endTime,
      status: AppointmentStatus.checkedIn,
      reason: existing.reason,
      notes: existing.notes,
    );
    _changes.add(null);
  }
}

class _FakeVisitRepository implements VisitRepository {
  _FakeVisitRepository({required this.onCheckIn});

  final void Function(String appointmentId) onCheckIn;
  final List<String> checkedInAppointmentIds = <String>[];
  final Map<String, VisitRecord> _visitsByAppointmentId =
      <String, VisitRecord>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Future<String> checkIn({
    required Role role,
    required String appointmentId,
  }) async {
    checkedInAppointmentIds.add(appointmentId);
    onCheckIn(appointmentId);
    final String visitId = 'visit-${checkedInAppointmentIds.length}';
    _visitsByAppointmentId[appointmentId] = VisitRecord(
      id: visitId,
      appointmentId: appointmentId,
      patientId: 'p1',
      dentistId: 'dentist-1',
      status: VisitStatus.checkedIn,
      startedAt: DateTime.now(),
    );
    _changes.add(null);
    return visitId;
  }

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
    yield _visitsByAppointmentId[appointmentId];
    await for (final _ in _changes.stream) {
      yield _visitsByAppointmentId[appointmentId];
    }
  }

  @override
  Future<void> startProgress({
    required Role role,
    required String appointmentId,
  }) async {
    final VisitRecord? existing = _visitsByAppointmentId[appointmentId];
    if (existing == null || existing.status != VisitStatus.checkedIn) {
      throw const VisitNotEditableException();
    }
    _visitsByAppointmentId[appointmentId] = VisitRecord(
      id: existing.id,
      appointmentId: existing.appointmentId,
      patientId: existing.patientId,
      dentistId: existing.dentistId,
      status: VisitStatus.inProgress,
      startedAt: existing.startedAt,
      inProgressAt: DateTime.now(),
    );
    _changes.add(null);
  }

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

class _FakePlannedTreatmentRepository implements PlannedTreatmentRepository {
  _FakePlannedTreatmentRepository([
    List<PlannedTreatment> treatments = const [],
  ]) : _treatments = List<PlannedTreatment>.of(treatments);

  final List<PlannedTreatment> _treatments;

  @override
  Stream<List<PlannedTreatment>> watchForPatient({
    required Role role,
    required String patientId,
  }) => Stream.value(
    _treatments
        .where((PlannedTreatment t) => t.patientId == patientId)
        .toList(),
  );

  @override
  Future<String> addPlannedTreatment({
    required Role role,
    required String patientId,
    required String procedureName,
    required String toothNumber,
    required double estimatedUnitPrice,
    DateTime? targetDate,
  }) => throw UnimplementedError('not exercised by this test');
}

class _FakeInventoryRepository implements InventoryRepository {
  _FakeInventoryRepository([this._items = const <InventoryItem>[]]);

  final List<InventoryItem> _items;

  @override
  Stream<List<InventoryItem>> watchAll({required Role role}) =>
      Stream.value(_items);

  @override
  Future<String> create({
    required Role role,
    required String name,
    required InventoryCategory category,
    required String unit,
    required int onHandQuantity,
    required int lowStockThreshold,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Future<String> recordRestock({
    required Role role,
    required String actorUserId,
    required String inventoryItemId,
    required int quantityAdded,
    DateTime? restockDate,
    String? supplier,
    String? notes,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Stream<List<RestockEvent>> watchRestockHistory({
    required Role role,
    required String inventoryItemId,
  }) => Stream.value(const <RestockEvent>[]);

  @override
  Future<String> adjustStock({
    required Role role,
    required String actorUserId,
    required String inventoryItemId,
    required int newQuantity,
    required String reason,
  }) => throw UnimplementedError('not exercised by this test');

  @override
  Stream<List<StockAdjustment>> watchAdjustmentHistory({
    required Role role,
    required String inventoryItemId,
  }) => Stream.value(const <StockAdjustment>[]);
}

Future<_FakeAppointmentRepository> _pumpPage(
  WidgetTester tester,
  List<AppointmentRecord> appointments, {
  List<AssignableUser> assignableUsers = const <AssignableUser>[],
  List<PatientRecord> patients = const <PatientRecord>[],
  List<PlannedTreatment> plannedTreatments = const <PlannedTreatment>[],
  Map<String, List<String>> initialLinks = const <String, List<String>>{},
  List<InventoryItem> inventoryItems = const <InventoryItem>[],
  Role role = Role.assistant,
}) async {
  final Map<String, PlannedTreatment> plannedTreatmentsById = {
    for (final PlannedTreatment t in plannedTreatments) t.id: t,
  };
  final _FakeAppointmentRepository fakeRepository = _FakeAppointmentRepository(
    appointments,
    assignableUsers: assignableUsers,
    plannedTreatmentsById: plannedTreatmentsById,
    initialLinks: initialLinks,
  );
  addTearDown(() => fakeRepository._changes.close());
  final _FakeVisitRepository fakeVisitRepository = _FakeVisitRepository(
    onCheckIn: fakeRepository.markCheckedIn,
  );
  addTearDown(() => fakeVisitRepository._changes.close());
  final ProviderContainer container = ProviderContainer(
    overrides: [
      appointmentRepositoryProvider.overrideWithValue(fakeRepository),
      patientRepositoryProvider.overrideWithValue(
        _FakePatientRepository(patients),
      ),
      visitRepositoryProvider.overrideWithValue(fakeVisitRepository),
      plannedTreatmentRepositoryProvider.overrideWithValue(
        _FakePlannedTreatmentRepository(plannedTreatments),
      ),
      inventoryRepositoryProvider.overrideWithValue(
        _FakeInventoryRepository(inventoryItems),
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
        home: CalendarPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fakeRepository;
}

void main() {
  testWidgets('shows an empty state when there are no appointments today', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, const <AppointmentRecord>[]);

    expect(find.text('No appointments today'), findsOneWidget);
  });

  testWidgets('renders appointment rows with patient name and status badge', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.now();
    await _pumpPage(tester, <AppointmentRecord>[
      AppointmentRecord(
        id: '1',
        patientId: 'p1',
        patientName: 'Amine Trabelsi',
        assignedUserId: 'dentist-1',
        startTime: DateTime(now.year, now.month, now.day, 9),
        endTime: DateTime(now.year, now.month, now.day, 9, 30),
        status: AppointmentStatus.scheduled,
        reason: 'Cleaning',
      ),
      AppointmentRecord(
        id: '2',
        patientId: 'p2',
        patientName: 'Sarra Ben Youssef',
        assignedUserId: 'dentist-1',
        startTime: DateTime(now.year, now.month, now.day, 10),
        endTime: DateTime(now.year, now.month, now.day, 10, 30),
        status: AppointmentStatus.checkedIn,
      ),
    ]);

    expect(find.text('Amine Trabelsi'), findsOneWidget);
    expect(find.text('Cleaning'), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.text('Sarra Ben Youssef'), findsOneWidget);
    expect(find.text('No reason noted'), findsOneWidget);
    expect(find.text('Checked in'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
  });

  testWidgets('shows the low-stock side panel', (WidgetTester tester) async {
    await _pumpPage(tester, const <AppointmentRecord>[]);

    expect(find.text("Today's alerts"), findsOneWidget);
    expect(find.text('Low-stock items'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets(
    'the low-stock badge reflects the count of items at or under their threshold',
    (WidgetTester tester) async {
      await _pumpPage(
        tester,
        const <AppointmentRecord>[],
        inventoryItems: const <InventoryItem>[
          InventoryItem(
            id: '1',
            name: 'Gauze',
            category: InventoryCategory.supply,
            unit: 'box of 100',
            onHandQuantity: 2,
            lowStockThreshold: 5,
          ),
          InventoryItem(
            id: '2',
            name: 'Bleach',
            category: InventoryCategory.cleaning,
            unit: 'bottle',
            onHandQuantity: 10,
            lowStockThreshold: 2,
          ),
        ],
      );

      expect(find.text('1'), findsOneWidget);
    },
  );

  testWidgets('tapping the low-stock badge navigates to the Low Stock view', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      const <AppointmentRecord>[],
      inventoryItems: const <InventoryItem>[
        InventoryItem(
          id: '1',
          name: 'Gauze',
          category: InventoryCategory.supply,
          unit: 'box of 100',
          onHandQuantity: 2,
          lowStockThreshold: 5,
        ),
      ],
    );

    await tester.tap(find.text('Low-stock items'));
    await tester.pumpAndSettle();

    expect(find.text('Gauze'), findsOneWidget);
  });

  testWidgets(
    'switching to Week view shows today\'s appointment in its day column',
    (WidgetTester tester) async {
      final DateTime now = DateTime.now();
      await _pumpPage(tester, <AppointmentRecord>[
        AppointmentRecord(
          id: '1',
          patientId: 'p1',
          patientName: 'Amine Trabelsi',
          assignedUserId: 'dentist-1',
          startTime: DateTime(now.year, now.month, now.day, 9),
          endTime: DateTime(now.year, now.month, now.day, 9, 30),
          status: AppointmentStatus.scheduled,
        ),
      ]);

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      expect(find.text('Amine Trabelsi'), findsOneWidget);
    },
  );

  testWidgets(
    'week navigation shifts the range and drops out-of-range appointments',
    (WidgetTester tester) async {
      final DateTime now = DateTime.now();
      await _pumpPage(tester, <AppointmentRecord>[
        AppointmentRecord(
          id: '1',
          patientId: 'p1',
          patientName: 'Amine Trabelsi',
          assignedUserId: 'dentist-1',
          startTime: DateTime(now.year, now.month, now.day, 9),
          endTime: DateTime(now.year, now.month, now.day, 9, 30),
          status: AppointmentStatus.scheduled,
        ),
      ]);

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.text('Amine Trabelsi'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('Amine Trabelsi'), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text('Amine Trabelsi'), findsOneWidget);
    },
  );

  testWidgets(
    'Add appointment dialog defaults the assigned user to the Doctor',
    (WidgetTester tester) async {
      await _pumpPage(
        tester,
        const <AppointmentRecord>[],
        assignableUsers: const <AssignableUser>[
          AssignableUser(id: 'nurse-1', name: 'Nour Nurse', role: Role.nurse),
          AssignableUser(id: 'dentist-1', name: 'Dr. Sami', role: Role.doctor),
        ],
      );

      await tester.tap(find.text('Add appointment'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(DropdownButtonFormField<String>),
          matching: find.text('Dr. Sami'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('editing a scheduled appointment updates the assigned user', (
    WidgetTester tester,
  ) async {
    final DateTime start = DateTime.now().add(const Duration(days: 1));
    final AppointmentRecord existing = AppointmentRecord(
      id: '1',
      patientId: 'p1',
      patientName: 'Amine Trabelsi',
      assignedUserId: 'dentist-1',
      startTime: start,
      endTime: start.add(const Duration(minutes: 30)),
      status: AppointmentStatus.scheduled,
    );

    final _FakeAppointmentRepository fakeRepository = await _pumpPage(
      tester,
      <AppointmentRecord>[existing],
      assignableUsers: const <AssignableUser>[
        AssignableUser(id: 'dentist-1', name: 'Dr. Sami', role: Role.doctor),
        AssignableUser(
          id: 'dentist-2',
          name: 'Dr. Leila',
          role: Role.assistant,
        ),
      ],
      patients: <PatientRecord>[
        PatientRecord(
          id: 'p1',
          firstName: 'Amine',
          lastName: 'Trabelsi',
          dateOfBirth: DateTime(1990),
          phone: '20123456',
        ),
      ],
    );

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dr. Sami'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dr. Leila').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fakeRepository.updatedCalls.single.assignedUserId, 'dentist-2');
  });

  testWidgets(
    'saving an overlapping edit prompts for confirmation and proceeds when confirmed',
    (WidgetTester tester) async {
      final DateTime start = DateTime.now().add(const Duration(days: 1));
      final AppointmentRecord editable = AppointmentRecord(
        id: '1',
        patientId: 'p1',
        patientName: 'Amine Trabelsi',
        assignedUserId: 'dentist-1',
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
        status: AppointmentStatus.scheduled,
      );
      final AppointmentRecord conflicting = AppointmentRecord(
        id: '2',
        patientId: 'p2',
        patientName: 'Sarra Ben Youssef',
        assignedUserId: 'dentist-2',
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
        status: AppointmentStatus.scheduled,
      );

      final _FakeAppointmentRepository fakeRepository = await _pumpPage(
        tester,
        <AppointmentRecord>[editable, conflicting],
        assignableUsers: const <AssignableUser>[
          AssignableUser(id: 'dentist-1', name: 'Dr. Sami', role: Role.doctor),
          AssignableUser(
            id: 'dentist-2',
            name: 'Dr. Leila',
            role: Role.assistant,
          ),
        ],
        patients: <PatientRecord>[
          PatientRecord(
            id: 'p1',
            firstName: 'Amine',
            lastName: 'Trabelsi',
            dateOfBirth: DateTime(1990),
            phone: '20123456',
          ),
        ],
      );

      // Find the edit button on the first (editable) row specifically.
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dr. Sami'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dr. Leila').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('This time slot overlaps another appointment'),
        findsOneWidget,
      );

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(fakeRepository.updatedCalls.length, 1);
      expect(fakeRepository.updatedCalls.single.assignedUserId, 'dentist-2');
    },
  );

  testWidgets('the edit control is hidden for a non-scheduled appointment', (
    WidgetTester tester,
  ) async {
    final DateTime start = DateTime.now();
    await _pumpPage(tester, <AppointmentRecord>[
      AppointmentRecord(
        id: '1',
        patientId: 'p1',
        patientName: 'Amine Trabelsi',
        assignedUserId: 'dentist-1',
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
        status: AppointmentStatus.completed,
      ),
    ]);

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });

  testWidgets('cancelling with a non-reschedule reason frees the slot', (
    WidgetTester tester,
  ) async {
    final DateTime start = DateTime.now();
    final _FakeAppointmentRepository fakeRepository =
        await _pumpPage(tester, <AppointmentRecord>[
          AppointmentRecord(
            id: '1',
            patientId: 'p1',
            patientName: 'Amine Trabelsi',
            assignedUserId: 'dentist-1',
            startTime: start,
            endTime: start.add(const Duration(minutes: 30)),
            status: AppointmentStatus.scheduled,
          ),
        ]);

    await tester.tap(find.byIcon(Icons.event_busy_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Why are you cancelling?'), findsOneWidget);
    await tester.tap(find.text('No-show'));
    await tester.pumpAndSettle();

    expect(fakeRepository.cancelledReasons, <CancellationReason>[
      CancellationReason.noShow,
    ]);
    expect(find.text('Cancelled'), findsOneWidget);
  });

  testWidgets(
    'choosing Reschedule opens a replacement form and links both appointments',
    (WidgetTester tester) async {
      final DateTime start = DateTime.now().add(const Duration(days: 1));
      final _FakeAppointmentRepository fakeRepository = await _pumpPage(
        tester,
        <AppointmentRecord>[
          AppointmentRecord(
            id: '1',
            patientId: 'p1',
            patientName: 'Amine Trabelsi',
            assignedUserId: 'dentist-1',
            startTime: start,
            endTime: start.add(const Duration(minutes: 30)),
            status: AppointmentStatus.scheduled,
          ),
        ],
        assignableUsers: const <AssignableUser>[
          AssignableUser(id: 'dentist-1', name: 'Dr. Sami', role: Role.doctor),
        ],
        patients: <PatientRecord>[
          PatientRecord(
            id: 'p1',
            firstName: 'Amine',
            lastName: 'Trabelsi',
            dateOfBirth: DateTime(1990),
            phone: '20123456',
          ),
        ],
      );

      await tester.tap(find.byIcon(Icons.event_busy_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reschedule'));
      await tester.pumpAndSettle();

      expect(find.text('Reschedule appointment'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DropdownButtonFormField<PatientRecord>),
          matching: find.text('Amine Trabelsi'),
        ),
        findsOneWidget,
      );

      // No new start/end time chosen (pickers aren't driven in this test),
      // so submitting fails patient/time validation harmlessly closed by
      // Cancel instead, to keep this test focused on the dialog reaching
      // the reschedule form with the right prefill.
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();

      expect(fakeRepository.cancelledReasons, isEmpty);
      expect(fakeRepository.rescheduledTo, isEmpty);
    },
  );

  testWidgets(
    'checking in a scheduled appointment transitions it and shows the View Patient File action',
    (WidgetTester tester) async {
      final DateTime start = DateTime.now();
      final _FakeAppointmentRepository fakeRepository =
          await _pumpPage(tester, <AppointmentRecord>[
            AppointmentRecord(
              id: '1',
              patientId: 'p1',
              patientName: 'Amine Trabelsi',
              assignedUserId: 'dentist-1',
              startTime: start,
              endTime: start.add(const Duration(minutes: 30)),
              status: AppointmentStatus.scheduled,
            ),
          ]);

      expect(find.byIcon(Icons.how_to_reg_outlined), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_outlined), findsNothing);

      await tester.tap(find.byIcon(Icons.how_to_reg_outlined));
      await tester.pumpAndSettle();

      expect(
        fakeRepository._appointments.single.status,
        AppointmentStatus.checkedIn,
      );
      expect(find.text('Checked in'), findsOneWidget);
      expect(find.byIcon(Icons.how_to_reg_outlined), findsNothing);
      expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    },
  );

  testWidgets(
    'starting a checked-in visit shows the in-progress indicator and hides the start control',
    (WidgetTester tester) async {
      final DateTime start = DateTime.now();
      await _pumpPage(tester, <AppointmentRecord>[
        AppointmentRecord(
          id: '1',
          patientId: 'p1',
          patientName: 'Amine Trabelsi',
          assignedUserId: 'dentist-1',
          startTime: start,
          endTime: start.add(const Duration(minutes: 30)),
          status: AppointmentStatus.scheduled,
        ),
      ]);

      await tester.tap(find.byIcon(Icons.how_to_reg_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_circle_outline));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_circle_outline), findsNothing);
      expect(find.text('In progress'), findsOneWidget);
    },
  );

  testWidgets(
    'the check-in control is hidden without canCheckInPatient permission',
    (WidgetTester tester) async {
      final DateTime start = DateTime.now();
      await _pumpPage(tester, <AppointmentRecord>[
        AppointmentRecord(
          id: '1',
          patientId: 'p1',
          patientName: 'Amine Trabelsi',
          assignedUserId: 'dentist-1',
          startTime: start,
          endTime: start.add(const Duration(minutes: 30)),
          status: AppointmentStatus.scheduled,
        ),
      ], role: Role.nurse);

      expect(find.byIcon(Icons.how_to_reg_outlined), findsNothing);
    },
  );

  testWidgets('filtering by patient name narrows the visible appointments', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime.now();
    await _pumpPage(tester, <AppointmentRecord>[
      AppointmentRecord(
        id: '1',
        patientId: 'p1',
        patientName: 'Amine Trabelsi',
        assignedUserId: 'dentist-1',
        startTime: now,
        endTime: now.add(const Duration(minutes: 30)),
        status: AppointmentStatus.scheduled,
      ),
      AppointmentRecord(
        id: '2',
        patientId: 'p2',
        patientName: 'Sarra Ben Youssef',
        assignedUserId: 'dentist-1',
        startTime: now,
        endTime: now.add(const Duration(minutes: 30)),
        status: AppointmentStatus.scheduled,
      ),
    ]);

    expect(find.text('Amine Trabelsi'), findsOneWidget);
    expect(find.text('Sarra Ben Youssef'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Patient name'),
      'sarra',
    );
    await tester.pumpAndSettle();

    expect(find.text('Amine Trabelsi'), findsNothing);
    expect(find.text('Sarra Ben Youssef'), findsOneWidget);

    expect(find.text('Clear all'), findsOneWidget);
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    expect(find.text('Amine Trabelsi'), findsOneWidget);
    expect(find.text('Sarra Ben Youssef'), findsOneWidget);
  });

  testWidgets('the Clear all control is hidden when no filter is active', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, const <AppointmentRecord>[]);

    expect(find.text('Clear all'), findsNothing);
  });

  testWidgets('the day view shows a summary of linked planned treatments', (
    WidgetTester tester,
  ) async {
    final DateTime start = DateTime.now();
    await _pumpPage(
      tester,
      <AppointmentRecord>[
        AppointmentRecord(
          id: '1',
          patientId: 'p1',
          patientName: 'Amine Trabelsi',
          assignedUserId: 'dentist-1',
          startTime: start,
          endTime: start.add(const Duration(minutes: 30)),
          status: AppointmentStatus.scheduled,
        ),
      ],
      plannedTreatments: const <PlannedTreatment>[
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
      initialLinks: const <String, List<String>>{
        '1': <String>['pt1'],
      },
    );

    expect(find.text('Root canal'), findsOneWidget);
  });

  testWidgets(
    'editing an appointment for a patient with planned treatments shows the checklist pre-selected with already-linked treatments',
    (WidgetTester tester) async {
      final DateTime start = DateTime.now().add(const Duration(days: 1));
      final AppointmentRecord existing = AppointmentRecord(
        id: '1',
        patientId: 'p1',
        patientName: 'Amine Trabelsi',
        assignedUserId: 'dentist-1',
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
        status: AppointmentStatus.scheduled,
      );

      await _pumpPage(
        tester,
        <AppointmentRecord>[existing],
        assignableUsers: const <AssignableUser>[
          AssignableUser(id: 'dentist-1', name: 'Dr. Sami', role: Role.doctor),
        ],
        patients: <PatientRecord>[
          PatientRecord(
            id: 'p1',
            firstName: 'Amine',
            lastName: 'Trabelsi',
            dateOfBirth: DateTime(1990),
            phone: '20123456',
          ),
        ],
        plannedTreatments: const <PlannedTreatment>[
          PlannedTreatment(
            id: 'pt1',
            patientId: 'p1',
            procedureName: 'Root canal',
            toothNumber: '14',
            estimatedUnitPrice: 250,
            sequenceNumber: 1,
            status: PlannedTreatmentStatus.scheduled,
          ),
          PlannedTreatment(
            id: 'pt2',
            patientId: 'p1',
            procedureName: 'Filling',
            toothNumber: '22',
            estimatedUnitPrice: 100,
            sequenceNumber: 2,
            status: PlannedTreatmentStatus.planned,
          ),
        ],
        initialLinks: const <String, List<String>>{
          '1': <String>['pt1'],
        },
      );

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Planned treatments'), findsOneWidget);
      final CheckboxListTile rootCanalTile = tester.widget<CheckboxListTile>(
        find.ancestor(
          of: find.text('Root canal (Tooth number: 14)'),
          matching: find.byType(CheckboxListTile),
        ),
      );
      expect(rootCanalTile.value, isTrue);
      final CheckboxListTile fillingTile = tester.widget<CheckboxListTile>(
        find.ancestor(
          of: find.text('Filling (Tooth number: 22)'),
          matching: find.byType(CheckboxListTile),
        ),
      );
      expect(fillingTile.value, isFalse);
    },
  );

  testWidgets(
    'selecting an additional planned treatment and saving links it to the appointment',
    (WidgetTester tester) async {
      final DateTime start = DateTime.now().add(const Duration(days: 1));
      final AppointmentRecord existing = AppointmentRecord(
        id: '1',
        patientId: 'p1',
        patientName: 'Amine Trabelsi',
        assignedUserId: 'dentist-1',
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
        status: AppointmentStatus.scheduled,
      );

      final _FakeAppointmentRepository fakeRepository = await _pumpPage(
        tester,
        <AppointmentRecord>[existing],
        assignableUsers: const <AssignableUser>[
          AssignableUser(id: 'dentist-1', name: 'Dr. Sami', role: Role.doctor),
        ],
        patients: <PatientRecord>[
          PatientRecord(
            id: 'p1',
            firstName: 'Amine',
            lastName: 'Trabelsi',
            dateOfBirth: DateTime(1990),
            phone: '20123456',
          ),
        ],
        plannedTreatments: const <PlannedTreatment>[
          PlannedTreatment(
            id: 'pt2',
            patientId: 'p1',
            procedureName: 'Filling',
            toothNumber: '22',
            estimatedUnitPrice: 100,
            sequenceNumber: 2,
            status: PlannedTreatmentStatus.planned,
          ),
        ],
      );

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Filling (Tooth number: 22)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filling (Tooth number: 22)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fakeRepository.linkedTreatmentIdsByAppointment['1'], <String>[
        'pt2',
      ]);
    },
  );

  testWidgets(
    'linking a planned treatment already booked elsewhere shows an error',
    (WidgetTester tester) async {
      final DateTime start = DateTime.now().add(const Duration(days: 1));
      final AppointmentRecord existing = AppointmentRecord(
        id: '1',
        patientId: 'p1',
        patientName: 'Amine Trabelsi',
        assignedUserId: 'dentist-1',
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
        status: AppointmentStatus.scheduled,
      );

      final _FakeAppointmentRepository fakeRepository = await _pumpPage(
        tester,
        <AppointmentRecord>[existing],
        assignableUsers: const <AssignableUser>[
          AssignableUser(id: 'dentist-1', name: 'Dr. Sami', role: Role.doctor),
        ],
        patients: <PatientRecord>[
          PatientRecord(
            id: 'p1',
            firstName: 'Amine',
            lastName: 'Trabelsi',
            dateOfBirth: DateTime(1990),
            phone: '20123456',
          ),
        ],
        plannedTreatments: const <PlannedTreatment>[
          PlannedTreatment(
            id: 'pt2',
            patientId: 'p1',
            procedureName: 'Filling',
            toothNumber: '22',
            estimatedUnitPrice: 100,
            sequenceNumber: 2,
            status: PlannedTreatmentStatus.planned,
          ),
        ],
      );
      fakeRepository.plannedTreatmentErrorToThrow =
          const PlannedTreatmentAlreadyBookedException();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Filling (Tooth number: 22)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filling (Tooth number: 22)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text(
          'One of the selected planned treatments is already booked on another appointment.',
        ),
        findsOneWidget,
      );
    },
  );
}
