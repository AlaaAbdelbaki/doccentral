import 'package:docentral/features/treatment_plan/data/planned_treatment_repository_impl.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment_status.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

AppDatabase _createInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late PlannedTreatmentRepositoryImpl repository;
  const Uuid uuid = Uuid();

  setUp(() {
    db = _createInMemoryDatabase();
    repository = PlannedTreatmentRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> seedPatient() async {
    final String id = uuid.v4();
    final DateTime now = DateTime.now();
    await db
        .into(db.patients)
        .insert(
          PatientsCompanion.insert(
            id: id,
            firstName: 'Amine',
            lastName: 'Trabelsi',
            dateOfBirth: DateTime(1990),
            phone: '20123456',
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  group('PlannedTreatmentRepositoryImpl.addPlannedTreatment', () {
    test('defaults to planned status', () async {
      final String patientId = await seedPatient();

      final String id = await repository.addPlannedTreatment(
        role: Role.doctor,
        patientId: patientId,
        procedureName: 'Root canal',
        toothNumber: '14',
        estimatedUnitPrice: 200,
      );

      final PlannedTreatmentRow row = await (db.select(
        db.plannedTreatments,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(row.status, PlannedTreatmentStatus.planned.name);
    });

    test(
      'auto-assigns sequence numbers as one past the current highest',
      () async {
        final String patientId = await seedPatient();

        final String firstId = await repository.addPlannedTreatment(
          role: Role.doctor,
          patientId: patientId,
          procedureName: 'Filling',
          toothNumber: '18',
          estimatedUnitPrice: 50,
        );
        final String secondId = await repository.addPlannedTreatment(
          role: Role.doctor,
          patientId: patientId,
          procedureName: 'Root canal',
          toothNumber: '14',
          estimatedUnitPrice: 200,
        );

        final PlannedTreatmentRow first = await (db.select(
          db.plannedTreatments,
        )..where((t) => t.id.equals(firstId))).getSingle();
        final PlannedTreatmentRow second = await (db.select(
          db.plannedTreatments,
        )..where((t) => t.id.equals(secondId))).getSingle();

        expect(first.sequenceNumber, 1);
        expect(second.sequenceNumber, 2);
      },
    );

    test('saves a null targetDate as "next available"', () async {
      final String patientId = await seedPatient();

      final String id = await repository.addPlannedTreatment(
        role: Role.doctor,
        patientId: patientId,
        procedureName: 'Filling',
        toothNumber: '18',
        estimatedUnitPrice: 50,
      );

      final PlannedTreatmentRow row = await (db.select(
        db.plannedTreatments,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(row.targetDate, isNull);
    });

    test('saves an explicit targetDate', () async {
      final String patientId = await seedPatient();
      final DateTime targetDate = DateTime(2026, 3, 1);

      final String id = await repository.addPlannedTreatment(
        role: Role.doctor,
        patientId: patientId,
        procedureName: 'Filling',
        toothNumber: '18',
        estimatedUnitPrice: 50,
        targetDate: targetDate,
      );

      final PlannedTreatmentRow row = await (db.select(
        db.plannedTreatments,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(row.targetDate?.toUtc(), targetDate.toUtc());
    });

    test('rejects an Assistant with PermissionDeniedException', () async {
      final String patientId = await seedPatient();

      expect(
        () => repository.addPlannedTreatment(
          role: Role.assistant,
          patientId: patientId,
          procedureName: 'Filling',
          toothNumber: '18',
          estimatedUnitPrice: 50,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('rejects a Nurse with PermissionDeniedException', () async {
      final String patientId = await seedPatient();

      expect(
        () => repository.addPlannedTreatment(
          role: Role.nurse,
          patientId: patientId,
          procedureName: 'Filling',
          toothNumber: '18',
          estimatedUnitPrice: 50,
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });

  group('PlannedTreatmentRepositoryImpl.watchForPatient', () {
    test('returns Planned Treatments in sequence order', () async {
      final String patientId = await seedPatient();
      await repository.addPlannedTreatment(
        role: Role.doctor,
        patientId: patientId,
        procedureName: 'Filling',
        toothNumber: '18',
        estimatedUnitPrice: 50,
      );
      await repository.addPlannedTreatment(
        role: Role.doctor,
        patientId: patientId,
        procedureName: 'Root canal',
        toothNumber: '14',
        estimatedUnitPrice: 200,
      );

      final treatments = await repository
          .watchForPatient(role: Role.assistant, patientId: patientId)
          .first;

      expect(treatments.length, 2);
      expect(treatments[0].procedureName, 'Filling');
      expect(treatments[0].sequenceNumber, 1);
      expect(treatments[1].procedureName, 'Root canal');
      expect(treatments[1].sequenceNumber, 2);
    });

    test('all three roles can view (canViewPatients is shared)', () async {
      final String patientId = await seedPatient();
      await repository.addPlannedTreatment(
        role: Role.doctor,
        patientId: patientId,
        procedureName: 'Filling',
        toothNumber: '18',
        estimatedUnitPrice: 50,
      );

      for (final Role role in Role.values) {
        final treatments = await repository
            .watchForPatient(role: role, patientId: patientId)
            .first;
        expect(treatments.length, 1, reason: '$role');
      }
    });
  });
}
