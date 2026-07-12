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
      expect(db.schemaVersion, 23);
      final rows = await db.select(db.patients).get();
      expect(rows, isEmpty);
    });

    test(
      'schema includes clinic locale/currency and the auth tables (v3)',
      () async {
        expect(db.schemaVersion, 23);
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
      expect(db.schemaVersion, 23);
      expect(await db.select(db.patientEditLogs).get(), isEmpty);
    });

    test('schema includes the appointments table (v5)', () async {
      expect(db.schemaVersion, 23);
      expect(await db.select(db.appointments).get(), isEmpty);
    });

    test('schema includes the appointment_edit_logs table (v6)', () async {
      expect(db.schemaVersion, 23);
      expect(await db.select(db.appointmentEditLogs).get(), isEmpty);
    });

    test(
      'schema includes the appointment_cancellations table and rescheduledToAppointmentId column (v7)',
      () async {
        expect(db.schemaVersion, 23);
        expect(await db.select(db.appointmentCancellations).get(), isEmpty);
      },
    );

    test('schema includes the visits table (v8)', () async {
      expect(db.schemaVersion, 23);
      expect(await db.select(db.visits).get(), isEmpty);
    });

    test('schema includes the visits.inProgressAt column (v9)', () async {
      expect(db.schemaVersion, 23);
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
      expect(db.schemaVersion, 23);
      expect(await db.select(db.performedTreatments).get(), isEmpty);
    });

    test(
      'schema includes visits.diagnosis and visits.clinicalNotes columns (v11)',
      () async {
        expect(db.schemaVersion, 23);
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
        expect(db.schemaVersion, 23);
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
      expect(db.schemaVersion, 23);
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
      expect(db.schemaVersion, 23);
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
      expect(db.schemaVersion, 23);
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

    test('schema includes the invoice_voids table (v16)', () async {
      expect(db.schemaVersion, 23);
      expect(await db.select(db.invoiceVoids).get(), isEmpty);

      final now = DateTime.now();
      const visitId = '00000000-0000-0000-0000-000000000017';
      const invoiceId = '00000000-0000-0000-0000-000000000018';
      const voidId = '00000000-0000-0000-0000-000000000019';
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
          .into(db.invoiceVoids)
          .insert(
            InvoiceVoidsCompanion.insert(
              id: voidId,
              invoiceId: invoiceId,
              actorUserId: 'dentist-1',
              reason: 'Billed to the wrong patient',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final void_ = await (db.select(
        db.invoiceVoids,
      )..where((t) => t.id.equals(voidId))).getSingle();
      expect(void_.invoiceId, invoiceId);
      expect(void_.reason, 'Billed to the wrong patient');
    });

    test('schema includes the planned_treatments table (v17)', () async {
      expect(db.schemaVersion, 23);
      expect(await db.select(db.plannedTreatments).get(), isEmpty);

      final now = DateTime.now();
      const treatmentId = '00000000-0000-0000-0000-000000000020';
      await db
          .into(db.plannedTreatments)
          .insert(
            PlannedTreatmentsCompanion.insert(
              id: treatmentId,
              patientId: 'patient-1',
              procedureName: 'Root canal',
              toothNumber: '14',
              estimatedUnitPrice: 200,
              sequenceNumber: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final treatment = await (db.select(
        db.plannedTreatments,
      )..where((t) => t.id.equals(treatmentId))).getSingle();
      expect(treatment.status, 'planned');
      expect(treatment.targetDate, isNull);
    });

    test(
      'schema includes the appointment_planned_treatments join table (v18)',
      () async {
        expect(db.schemaVersion, 23);
        expect(await db.select(db.appointmentPlannedTreatments).get(), isEmpty);

        final now = DateTime.now();
        const linkId = '00000000-0000-0000-0000-000000000021';
        await db
            .into(db.appointmentPlannedTreatments)
            .insert(
              AppointmentPlannedTreatmentsCompanion.insert(
                id: linkId,
                appointmentId: 'appointment-1',
                plannedTreatmentId: 'treatment-1',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final link = await (db.select(
          db.appointmentPlannedTreatments,
        )..where((t) => t.id.equals(linkId))).getSingle();
        expect(link.appointmentId, 'appointment-1');
        expect(link.plannedTreatmentId, 'treatment-1');
      },
    );

    test('schema includes the inventory_items table (v19)', () async {
      expect(db.schemaVersion, 23);
      expect(await db.select(db.inventoryItems).get(), isEmpty);

      final now = DateTime.now();
      const itemId = '00000000-0000-0000-0000-000000000022';
      await db
          .into(db.inventoryItems)
          .insert(
            InventoryItemsCompanion.insert(
              id: itemId,
              name: 'Gauze',
              category: 'supply',
              unit: 'box of 100',
              onHandQuantity: 20,
              lowStockThreshold: 5,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final item = await (db.select(
        db.inventoryItems,
      )..where((t) => t.id.equals(itemId))).getSingle();
      expect(item.name, 'Gauze');
      expect(item.category, 'supply');
      expect(item.onHandQuantity, 20);
      expect(item.lowStockThreshold, 5);
    });

    test('schema includes the restock_events table (v20)', () async {
      expect(db.schemaVersion, 23);
      expect(await db.select(db.restockEvents).get(), isEmpty);

      final now = DateTime.now();
      const eventId = '00000000-0000-0000-0000-000000000023';
      await db
          .into(db.restockEvents)
          .insert(
            RestockEventsCompanion.insert(
              id: eventId,
              inventoryItemId: 'item-1',
              quantityAdded: 15,
              restockDate: now,
              actorUserId: 'actor-1',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final event = await (db.select(
        db.restockEvents,
      )..where((t) => t.id.equals(eventId))).getSingle();
      expect(event.inventoryItemId, 'item-1');
      expect(event.quantityAdded, 15);
      expect(event.supplier, isNull);
      expect(event.notes, isNull);
    });

    test('schema includes the stock_adjustments table (v21)', () async {
      expect(db.schemaVersion, 23);
      expect(await db.select(db.stockAdjustments).get(), isEmpty);

      final now = DateTime.now();
      const adjustmentId = '00000000-0000-0000-0000-000000000024';
      await db
          .into(db.stockAdjustments)
          .insert(
            StockAdjustmentsCompanion.insert(
              id: adjustmentId,
              inventoryItemId: 'item-1',
              oldQuantity: 20,
              newQuantity: 18,
              delta: -2,
              reason: 'Recounted after inventory audit',
              actorUserId: 'actor-1',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final adjustment = await (db.select(
        db.stockAdjustments,
      )..where((t) => t.id.equals(adjustmentId))).getSingle();
      expect(adjustment.oldQuantity, 20);
      expect(adjustment.newQuantity, 18);
      expect(adjustment.delta, -2);
      expect(adjustment.reason, 'Recounted after inventory audit');
    });

    test('schema includes the day_closeouts table (v22)', () async {
      expect(db.schemaVersion, 23);
      expect(await db.select(db.dayCloseouts).get(), isEmpty);

      final now = DateTime.now();
      const closeoutId = '00000000-0000-0000-0000-000000000025';
      await db
          .into(db.dayCloseouts)
          .insert(
            DayCloseoutsCompanion.insert(
              id: closeoutId,
              closeoutDate: DateTime(2026, 6, 8),
              expectedCash: 100,
              countedCash: 95,
              delta: 5,
              actorUserId: 'actor-1',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final closeout = await (db.select(
        db.dayCloseouts,
      )..where((t) => t.id.equals(closeoutId))).getSingle();
      expect(closeout.expectedCash, 100);
      expect(closeout.countedCash, 95);
      expect(closeout.delta, 5);
    });

    test(
      'schema includes day_closeouts.reopenedAt and the day_closeout_reopen_logs table (v23)',
      () async {
        expect(db.schemaVersion, 23);
        expect(await db.select(db.dayCloseoutReopenLogs).get(), isEmpty);

        final now = DateTime.now();
        const closeoutId = '00000000-0000-0000-0000-000000000026';
        await db
            .into(db.dayCloseouts)
            .insert(
              DayCloseoutsCompanion.insert(
                id: closeoutId,
                closeoutDate: DateTime(2026, 6, 9),
                expectedCash: 100,
                countedCash: 95,
                delta: 5,
                actorUserId: 'actor-1',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final closeout = await (db.select(
          db.dayCloseouts,
        )..where((t) => t.id.equals(closeoutId))).getSingle();
        expect(closeout.reopenedAt, isNull);

        const logId = '00000000-0000-0000-0000-000000000027';
        await db
            .into(db.dayCloseoutReopenLogs)
            .insert(
              DayCloseoutReopenLogsCompanion.insert(
                id: logId,
                dayCloseoutId: closeoutId,
                actorUserId: 'doctor-1',
                reason: 'Missed cash payment needs correction',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final log = await (db.select(
          db.dayCloseoutReopenLogs,
        )..where((t) => t.id.equals(logId))).getSingle();
        expect(log.dayCloseoutId, closeoutId);
        expect(log.reason, 'Missed cash payment needs correction');
      },
    );
  });
}
