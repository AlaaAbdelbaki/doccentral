import 'dart:async';

import 'package:docentral/features/visit/domain/performed_treatment.dart';
import 'package:docentral/features/visit/domain/performed_treatment_repository.dart';
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

  final VisitRecord? _visit;

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
  }) => Stream.value(_visit);

  @override
  Future<void> startProgress({
    required Role role,
    required String appointmentId,
  }) => throw UnimplementedError('not exercised by this test');
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
}

Future<_FakePerformedTreatmentRepository> _pumpPage(
  WidgetTester tester, {
  required VisitRecord? visit,
  List<PerformedTreatment> treatments = const <PerformedTreatment>[],
  Role role = Role.assistant,
}) async {
  final _FakePerformedTreatmentRepository fakeTreatmentRepository =
      _FakePerformedTreatmentRepository(treatments);
  addTearDown(() => fakeTreatmentRepository._changes.close());

  final ProviderContainer container = ProviderContainer(
    overrides: [
      visitRepositoryProvider.overrideWithValue(_FakeVisitRepository(visit)),
      performedTreatmentRepositoryProvider.overrideWithValue(
        fakeTreatmentRepository,
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
  return fakeTreatmentRepository;
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
    final _FakePerformedTreatmentRepository fakeRepository = await _pumpPage(
      tester,
      visit: inProgressVisit,
    );

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
    final _FakePerformedTreatmentRepository fakeRepository = await _pumpPage(
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
    );

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
}
