import 'package:docentral/features/visit/data/performed_treatment_repository_impl.dart';
import 'package:docentral/features/visit/domain/performed_treatment.dart';
import 'package:docentral/features/visit/domain/visit_exceptions.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

AppDatabase _createInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late PerformedTreatmentRepositoryImpl repository;
  const Uuid uuid = Uuid();

  setUp(() {
    db = _createInMemoryDatabase();
    repository = PerformedTreatmentRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> seedVisit({String status = 'inProgress'}) async {
    final String patientId = uuid.v4();
    final String appointmentId = uuid.v4();
    final String visitId = uuid.v4();
    final DateTime now = DateTime.now();

    await db
        .into(db.patients)
        .insert(
          PatientsCompanion.insert(
            id: patientId,
            firstName: 'Amine',
            lastName: 'Trabelsi',
            dateOfBirth: DateTime(1990),
            phone: '20123456',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.appointments)
        .insert(
          AppointmentsCompanion.insert(
            id: appointmentId,
            patientId: patientId,
            assignedUserId: 'dentist-1',
            startTime: now,
            endTime: now.add(const Duration(minutes: 30)),
            status: const Value('checkedIn'),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.visits)
        .insert(
          VisitsCompanion.insert(
            id: visitId,
            appointmentId: appointmentId,
            patientId: patientId,
            dentistId: 'dentist-1',
            status: Value(status),
            startedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return visitId;
  }

  group('PerformedTreatmentRepositoryImpl.addTreatment', () {
    test(
      'saves the treatment timestamped and attributed to the recording user',
      () async {
        final String visitId = await seedVisit();

        final String id = await repository.addTreatment(
          role: Role.assistant,
          actorUserId: 'actor-1',
          visitId: visitId,
          toothNumber: '18',
          procedureName: 'Filling',
          unitPrice: 50,
          quantity: 1,
        );

        final List<PerformedTreatment> treatments = await repository
            .watchForVisit(role: Role.assistant, visitId: visitId)
            .first;

        expect(treatments.single.id, id);
        expect(treatments.single.toothNumber, '18');
        expect(treatments.single.procedureName, 'Filling');
        expect(treatments.single.unitPrice, 50);
        expect(treatments.single.quantity, 1);
        expect(treatments.single.recordedByUserId, 'actor-1');
        expect(treatments.single.recordedAt, isNotNull);
        expect(treatments.single.totalPrice, 50);
      },
    );

    test(
      'throws VisitNotEditableException when the Visit is not in_progress',
      () async {
        final String visitId = await seedVisit(status: 'checkedIn');

        expect(
          () => repository.addTreatment(
            role: Role.assistant,
            actorUserId: 'actor-1',
            visitId: visitId,
            toothNumber: '18',
            procedureName: 'Filling',
            unitPrice: 50,
            quantity: 1,
          ),
          throwsA(isA<VisitNotEditableException>()),
        );
      },
    );
  });

  group('PerformedTreatmentRepositoryImpl.updateTreatment', () {
    test('updates and the list reflects the change immediately', () async {
      final String visitId = await seedVisit();
      final String id = await repository.addTreatment(
        role: Role.assistant,
        actorUserId: 'actor-1',
        visitId: visitId,
        toothNumber: '18',
        procedureName: 'Filling',
        unitPrice: 50,
        quantity: 1,
      );

      await repository.updateTreatment(
        role: Role.assistant,
        treatmentId: id,
        toothNumber: '19',
        procedureName: 'Crown',
        unitPrice: 200,
        quantity: 2,
      );

      final List<PerformedTreatment> treatments = await repository
          .watchForVisit(role: Role.assistant, visitId: visitId)
          .first;

      expect(treatments.single.toothNumber, '19');
      expect(treatments.single.procedureName, 'Crown');
      expect(treatments.single.unitPrice, 200);
      expect(treatments.single.quantity, 2);
    });

    test(
      'throws VisitNotEditableException when the parent Visit is completed',
      () async {
        final String visitId = await seedVisit();
        final String id = await repository.addTreatment(
          role: Role.assistant,
          actorUserId: 'actor-1',
          visitId: visitId,
          toothNumber: '18',
          procedureName: 'Filling',
          unitPrice: 50,
          quantity: 1,
        );

        await (db.update(db.visits)..where((t) => t.id.equals(visitId))).write(
          const VisitsCompanion(status: Value('completed')),
        );

        expect(
          () => repository.updateTreatment(
            role: Role.assistant,
            treatmentId: id,
            toothNumber: '19',
            procedureName: 'Crown',
            unitPrice: 200,
            quantity: 2,
          ),
          throwsA(isA<VisitNotEditableException>()),
        );
      },
    );
  });

  group('PerformedTreatmentRepositoryImpl.removeTreatment', () {
    test(
      'soft-deletes the treatment and it disappears from the list',
      () async {
        final String visitId = await seedVisit();
        final String id = await repository.addTreatment(
          role: Role.assistant,
          actorUserId: 'actor-1',
          visitId: visitId,
          toothNumber: '18',
          procedureName: 'Filling',
          unitPrice: 50,
          quantity: 1,
        );

        await repository.removeTreatment(role: Role.assistant, treatmentId: id);

        final List<PerformedTreatment> treatments = await repository
            .watchForVisit(role: Role.assistant, visitId: visitId)
            .first;
        expect(treatments, isEmpty);
      },
    );

    test(
      'a completed Visit rejects removal — Performed Treatments are locked on completion',
      () async {
        final String visitId = await seedVisit();
        final String id = await repository.addTreatment(
          role: Role.assistant,
          actorUserId: 'actor-1',
          visitId: visitId,
          toothNumber: '18',
          procedureName: 'Filling',
          unitPrice: 50,
          quantity: 1,
        );

        await (db.update(db.visits)..where((t) => t.id.equals(visitId))).write(
          const VisitsCompanion(status: Value('completed')),
        );

        expect(
          () =>
              repository.removeTreatment(role: Role.assistant, treatmentId: id),
          throwsA(isA<VisitNotEditableException>()),
        );

        final List<PerformedTreatment> treatments = await repository
            .watchForVisit(role: Role.assistant, visitId: visitId)
            .first;
        expect(treatments.length, 1);
      },
    );
  });
}
