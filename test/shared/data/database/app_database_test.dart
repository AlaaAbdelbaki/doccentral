import 'package:docentral/shared/data/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase _createInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createInMemoryDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase', () {
    test('initializes without error', () async {
      // Triggers schema creation
      final count = await db.select(db.clinics).get();
      expect(count, isEmpty);
    });

    test('inserts a clinic row and reads it back', () async {
      final now = DateTime.now();
      const clinicId = '00000000-0000-0000-0000-000000000001';

      await db
          .into(db.clinics)
          .insert(
            ClinicsCompanion.insert(
              id: clinicId,
              name: 'Cabinet Dentaire Test',
              createdAt: now,
              updatedAt: now,
              syncStatus: const Value('pending'),
            ),
          );

      final rows = await db.select(db.clinics).get();
      expect(rows.length, 1);

      final clinic = rows.first;
      expect(clinic.id, clinicId);
      expect(clinic.name, 'Cabinet Dentaire Test');
      expect(clinic.syncStatus, 'pending');
      expect(clinic.deletedAt, isNull);
    });

    test('sync metadata defaults syncStatus to pending', () async {
      final now = DateTime.now();
      const clinicId = '00000000-0000-0000-0000-000000000002';

      await db
          .into(db.clinics)
          .insert(
            ClinicsCompanion.insert(
              id: clinicId,
              name: 'Test Clinic',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final clinic = await (db.select(
        db.clinics,
      )..where((t) => t.id.equals(clinicId))).getSingle();

      expect(clinic.syncStatus, 'pending');
    });

    test('soft delete sets deletedAt and preserves row', () async {
      final now = DateTime.now();
      const clinicId = '00000000-0000-0000-0000-000000000003';

      await db
          .into(db.clinics)
          .insert(
            ClinicsCompanion.insert(
              id: clinicId,
              name: 'To Be Deleted',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await (db.update(db.clinics)..where((t) => t.id.equals(clinicId))).write(
        ClinicsCompanion(
          deletedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );

      final clinic = await (db.select(
        db.clinics,
      )..where((t) => t.id.equals(clinicId))).getSingle();

      expect(clinic.deletedAt, isNotNull);
      expect(clinic.name, 'To Be Deleted');
    });

    test('schema includes the patients table (v2)', () async {
      expect(db.schemaVersion, 11);
      final rows = await db.select(db.patients).get();
      expect(rows, isEmpty);
    });

    test(
      'schema includes clinic locale/currency and the auth tables (v3)',
      () async {
        expect(db.schemaVersion, 11);
        expect(await db.select(db.users).get(), isEmpty);
        expect(await db.select(db.roles).get(), isEmpty);
        expect(await db.select(db.userRoles).get(), isEmpty);

        final now = DateTime.now();
        const clinicId = '00000000-0000-0000-0000-000000000004';
        await db
            .into(db.clinics)
            .insert(
              ClinicsCompanion.insert(
                id: clinicId,
                name: 'Locale Test',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final clinic = await (db.select(
          db.clinics,
        )..where((t) => t.id.equals(clinicId))).getSingle();
        expect(clinic.locale, 'fr-TN');
        expect(clinic.currency, 'TND');
      },
    );

    test('schema includes the patient_edit_logs table (v4)', () async {
      expect(db.schemaVersion, 11);
      expect(await db.select(db.patientEditLogs).get(), isEmpty);
    });

    test('schema includes the appointments table (v5)', () async {
      expect(db.schemaVersion, 11);
      expect(await db.select(db.appointments).get(), isEmpty);
    });

    test('schema includes the appointment_edit_logs table (v6)', () async {
      expect(db.schemaVersion, 11);
      expect(await db.select(db.appointmentEditLogs).get(), isEmpty);
    });

    test(
      'schema includes the appointment_cancellations table and rescheduledToAppointmentId column (v7)',
      () async {
        expect(db.schemaVersion, 11);
        expect(await db.select(db.appointmentCancellations).get(), isEmpty);
      },
    );

    test('schema includes the visits table (v8)', () async {
      expect(db.schemaVersion, 11);
      expect(await db.select(db.visits).get(), isEmpty);
    });

    test('schema includes the visits.inProgressAt column (v9)', () async {
      expect(db.schemaVersion, 11);
      final now = DateTime.now();
      const visitId = '00000000-0000-0000-0000-000000000005';
      await db
          .into(db.visits)
          .insert(
            VisitsCompanion.insert(
              id: visitId,
              appointmentId: 'appointment-1',
              patientId: 'patient-1',
              dentistId: 'dentist-1',
              startedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final visit = await (db.select(
        db.visits,
      )..where((t) => t.id.equals(visitId))).getSingle();
      expect(visit.inProgressAt, isNull);
    });

    test('schema includes the performed_treatments table (v10)', () async {
      expect(db.schemaVersion, 11);
      expect(await db.select(db.performedTreatments).get(), isEmpty);
    });

    test(
      'schema includes visits.diagnosis and visits.clinicalNotes columns (v11)',
      () async {
        expect(db.schemaVersion, 11);
        final now = DateTime.now();
        const visitId = '00000000-0000-0000-0000-000000000006';
        await db
            .into(db.visits)
            .insert(
              VisitsCompanion.insert(
                id: visitId,
                appointmentId: 'appointment-1',
                patientId: 'patient-1',
                dentistId: 'dentist-1',
                startedAt: now,
                createdAt: now,
                updatedAt: now,
              ),
            );

        final visit = await (db.select(
          db.visits,
        )..where((t) => t.id.equals(visitId))).getSingle();
        expect(visit.diagnosis, isNull);
        expect(visit.clinicalNotes, isNull);
      },
    );
  });
}
