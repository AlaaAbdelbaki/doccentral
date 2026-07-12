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
      expect(db.schemaVersion, 15);
      final rows = await db.select(db.patients).get();
      expect(rows, isEmpty);
    });

    test(
      'schema includes clinic locale/currency and the auth tables (v3)',
      () async {
        expect(db.schemaVersion, 15);
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
      expect(db.schemaVersion, 15);
      expect(await db.select(db.patientEditLogs).get(), isEmpty);
    });

    test('schema includes the appointments table (v5)', () async {
      expect(db.schemaVersion, 15);
      expect(await db.select(db.appointments).get(), isEmpty);
    });

    test('schema includes the appointment_edit_logs table (v6)', () async {
      expect(db.schemaVersion, 15);
      expect(await db.select(db.appointmentEditLogs).get(), isEmpty);
    });

    test(
      'schema includes the appointment_cancellations table and rescheduledToAppointmentId column (v7)',
      () async {
        expect(db.schemaVersion, 15);
        expect(await db.select(db.appointmentCancellations).get(), isEmpty);
      },
    );

    test('schema includes the visits table (v8)', () async {
      expect(db.schemaVersion, 15);
      expect(await db.select(db.visits).get(), isEmpty);
    });

    test('schema includes the visits.inProgressAt column (v9)', () async {
      expect(db.schemaVersion, 15);
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
      expect(db.schemaVersion, 15);
      expect(await db.select(db.performedTreatments).get(), isEmpty);
    });

    test(
      'schema includes visits.diagnosis and visits.clinicalNotes columns (v11)',
      () async {
        expect(db.schemaVersion, 15);
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

    test(
      'schema includes visits.endedAt and the invoices/invoice_items tables (v12)',
      () async {
        expect(db.schemaVersion, 15);
        final now = DateTime.now();
        const visitId = '00000000-0000-0000-0000-000000000007';
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
        expect(visit.endedAt, isNull);

        expect(await db.select(db.invoices).get(), isEmpty);
        expect(await db.select(db.invoiceItems).get(), isEmpty);

        const invoiceId = '00000000-0000-0000-0000-000000000008';
        await db
            .into(db.invoices)
            .insert(
              InvoicesCompanion.insert(
                id: invoiceId,
                patientId: 'patient-1',
                visitId: visitId,
                totalAmount: 100,
                createdByUserId: 'dentist-1',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final invoice = await (db.select(
          db.invoices,
        )..where((t) => t.id.equals(invoiceId))).getSingle();
        expect(invoice.status, 'draft');
      },
    );

    test('schema includes the visit_unlock_logs table (v13)', () async {
      expect(db.schemaVersion, 15);
      expect(await db.select(db.visitUnlockLogs).get(), isEmpty);

      final now = DateTime.now();
      const visitId = '00000000-0000-0000-0000-000000000009';
      const logId = '00000000-0000-0000-0000-000000000010';
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
      await db
          .into(db.visitUnlockLogs)
          .insert(
            VisitUnlockLogsCompanion.insert(
              id: logId,
              visitId: visitId,
              actorUserId: 'dentist-1',
              reason: 'Test reason',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final log = await (db.select(
        db.visitUnlockLogs,
      )..where((t) => t.id.equals(logId))).getSingle();
      expect(log.visitId, visitId);
      expect(log.reason, 'Test reason');
    });

    test('schema includes the invoice_finalizations table (v14)', () async {
      expect(db.schemaVersion, 15);
      expect(await db.select(db.invoiceFinalizations).get(), isEmpty);

      final now = DateTime.now();
      const visitId = '00000000-0000-0000-0000-000000000011';
      const invoiceId = '00000000-0000-0000-0000-000000000012';
      const finalizationId = '00000000-0000-0000-0000-000000000013';
      await db
          .into(db.invoices)
          .insert(
            InvoicesCompanion.insert(
              id: invoiceId,
              patientId: 'patient-1',
              visitId: visitId,
              totalAmount: 100,
              createdByUserId: 'dentist-1',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.invoiceFinalizations)
          .insert(
            InvoiceFinalizationsCompanion.insert(
              id: finalizationId,
              invoiceId: invoiceId,
              actorUserId: 'assistant-1',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final finalization = await (db.select(
        db.invoiceFinalizations,
      )..where((t) => t.id.equals(finalizationId))).getSingle();
      expect(finalization.invoiceId, invoiceId);
      expect(finalization.actorUserId, 'assistant-1');
    });

    test('schema includes the payments table (v15)', () async {
      expect(db.schemaVersion, 15);
      expect(await db.select(db.payments).get(), isEmpty);

      final now = DateTime.now();
      const visitId = '00000000-0000-0000-0000-000000000014';
      const invoiceId = '00000000-0000-0000-0000-000000000015';
      const paymentId = '00000000-0000-0000-0000-000000000016';
      await db
          .into(db.invoices)
          .insert(
            InvoicesCompanion.insert(
              id: invoiceId,
              patientId: 'patient-1',
              visitId: visitId,
              totalAmount: 100,
              createdByUserId: 'dentist-1',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.payments)
          .insert(
            PaymentsCompanion.insert(
              id: paymentId,
              invoiceId: invoiceId,
              amount: 40,
              paymentDate: now,
              recordedByUserId: 'assistant-1',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final payment = await (db.select(
        db.payments,
      )..where((t) => t.id.equals(paymentId))).getSingle();
      expect(payment.invoiceId, invoiceId);
      expect(payment.amount, 40);
      expect(payment.method, 'cash');
      expect(payment.notes, isNull);
    });
  });
}
