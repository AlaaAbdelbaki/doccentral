import 'package:docentral/features/appointment/domain/appointment_exceptions.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
import 'package:docentral/features/invoice/domain/invoice_status.dart';
import 'package:docentral/features/visit/data/performed_treatment_repository_impl.dart';
import 'package:docentral/features/visit/data/visit_repository_impl.dart';
import 'package:docentral/features/visit/domain/visit_exceptions.dart';
import 'package:docentral/features/visit/domain/visit_record.dart';
import 'package:docentral/features/visit/domain/visit_status.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
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
  late VisitRepositoryImpl repository;
  const Uuid uuid = Uuid();

  setUp(() {
    db = _createInMemoryDatabase();
    repository = VisitRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> seedPatient(String firstName, String lastName) async {
    final String id = uuid.v4();
    final DateTime now = DateTime.now();
    await db
        .into(db.patients)
        .insert(
          PatientsCompanion.insert(
            id: id,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: DateTime(1990),
            phone: '20123456',
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<String> seedAppointment({
    required String patientId,
    String status = 'scheduled',
  }) async {
    final String id = uuid.v4();
    final DateTime now = DateTime.now();
    await db
        .into(db.appointments)
        .insert(
          AppointmentsCompanion.insert(
            id: id,
            patientId: patientId,
            assignedUserId: 'dentist-1',
            startTime: now,
            endTime: now.add(const Duration(minutes: 30)),
            status: Value(status),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  group('VisitRepositoryImpl.checkIn', () {
    test(
      'transitions the appointment to checked_in and creates a linked Visit with started_at set',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final String appointmentId = await seedAppointment(
          patientId: patientId,
        );

        final String visitId = await repository.checkIn(
          role: Role.assistant,
          appointmentId: appointmentId,
        );

        final Appointment appointment = await (db.select(
          db.appointments,
        )..where((t) => t.id.equals(appointmentId))).getSingle();
        expect(appointment.status, AppointmentStatus.checkedIn.name);

        final Visit visit = await (db.select(
          db.visits,
        )..where((t) => t.id.equals(visitId))).getSingle();
        expect(visit.appointmentId, appointmentId);
        expect(visit.patientId, patientId);
        expect(visit.dentistId, 'dentist-1');
        expect(visit.status, VisitStatus.checkedIn.name);
        expect(visit.startedAt, isNotNull);
      },
    );

    test(
      'throws AppointmentNotEditableException for a non-scheduled appointment',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final String appointmentId = await seedAppointment(
          patientId: patientId,
          status: 'cancelled',
        );

        expect(
          () => repository.checkIn(
            role: Role.assistant,
            appointmentId: appointmentId,
          ),
          throwsA(isA<AppointmentNotEditableException>()),
        );

        final List<Visit> visits = await db.select(db.visits).get();
        expect(visits, isEmpty);
      },
    );
  });

  group('VisitRepositoryImpl.watchRecentVisits', () {
    test(
      'returns the most recent visits for the patient, newest first, capped at limit',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final String otherPatientId = await seedPatient('Sarra', 'Ben Youssef');

        final List<String> appointmentIds = <String>[];
        for (int i = 0; i < 4; i++) {
          appointmentIds.add(await seedAppointment(patientId: patientId));
        }
        final String otherAppointmentId = await seedAppointment(
          patientId: otherPatientId,
        );

        for (final String appointmentId in appointmentIds) {
          await repository.checkIn(
            role: Role.assistant,
            appointmentId: appointmentId,
          );
        }
        await repository.checkIn(
          role: Role.assistant,
          appointmentId: otherAppointmentId,
        );

        final List<VisitRecord> recent = await repository
            .watchRecentVisits(role: Role.assistant, patientId: patientId)
            .first;

        expect(recent.length, 3);
        expect(
          recent.every((VisitRecord v) => v.patientId == patientId),
          isTrue,
        );
      },
    );
  });

  group('VisitRepositoryImpl.startProgress', () {
    test(
      'transitions the Visit to in_progress and captures a non-null in_progress_at',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final String appointmentId = await seedAppointment(
          patientId: patientId,
        );
        final String visitId = await repository.checkIn(
          role: Role.assistant,
          appointmentId: appointmentId,
        );

        await repository.startProgress(
          role: Role.assistant,
          appointmentId: appointmentId,
        );

        final Visit visit = await (db.select(
          db.visits,
        )..where((t) => t.id.equals(visitId))).getSingle();
        expect(visit.status, VisitStatus.inProgress.name);
        expect(visit.inProgressAt, isNotNull);
      },
    );

    test(
      'throws VisitNotEditableException when the Visit is not checked_in',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final String appointmentId = await seedAppointment(
          patientId: patientId,
        );
        await repository.checkIn(
          role: Role.assistant,
          appointmentId: appointmentId,
        );
        await repository.startProgress(
          role: Role.assistant,
          appointmentId: appointmentId,
        );

        expect(
          () => repository.startProgress(
            role: Role.assistant,
            appointmentId: appointmentId,
          ),
          throwsA(isA<VisitNotEditableException>()),
        );
      },
    );
  });

  group('VisitRepositoryImpl.watchVisitForAppointment', () {
    test('returns null when no Visit exists for the appointment', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final String appointmentId = await seedAppointment(patientId: patientId);

      final VisitRecord? visit = await repository
          .watchVisitForAppointment(
            role: Role.assistant,
            appointmentId: appointmentId,
          )
          .first;

      expect(visit, isNull);
    });

    test('returns the linked Visit once checked in', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final String appointmentId = await seedAppointment(patientId: patientId);
      final String visitId = await repository.checkIn(
        role: Role.assistant,
        appointmentId: appointmentId,
      );

      final VisitRecord? visit = await repository
          .watchVisitForAppointment(
            role: Role.assistant,
            appointmentId: appointmentId,
          )
          .first;

      expect(visit?.id, visitId);
      expect(visit?.status, VisitStatus.checkedIn);
    });
  });

  group('VisitRepositoryImpl.updateClinicalRecord', () {
    test(
      'saves diagnosis and clinical notes on an in_progress Visit',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final String appointmentId = await seedAppointment(
          patientId: patientId,
        );
        final String visitId = await repository.checkIn(
          role: Role.assistant,
          appointmentId: appointmentId,
        );
        await repository.startProgress(
          role: Role.assistant,
          appointmentId: appointmentId,
        );

        await repository.updateClinicalRecord(
          role: Role.assistant,
          visitId: visitId,
          diagnosis: 'Cavity on tooth 18',
          clinicalNotes: 'Patient tolerated well',
        );

        final Visit visit = await (db.select(
          db.visits,
        )..where((t) => t.id.equals(visitId))).getSingle();
        expect(visit.diagnosis, 'Cavity on tooth 18');
        expect(visit.clinicalNotes, 'Patient tolerated well');
      },
    );

    test(
      'throws VisitNotEditableException when the Visit is not in_progress',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final String appointmentId = await seedAppointment(
          patientId: patientId,
        );
        final String visitId = await repository.checkIn(
          role: Role.assistant,
          appointmentId: appointmentId,
        );

        expect(
          () => repository.updateClinicalRecord(
            role: Role.assistant,
            visitId: visitId,
            diagnosis: 'Cavity',
            clinicalNotes: 'Notes',
          ),
          throwsA(isA<VisitNotEditableException>()),
        );
      },
    );
  });

  group('VisitRepositoryImpl.completeVisit', () {
    Future<String> checkInAndStart(String patientId) async {
      final String appointmentId = await seedAppointment(patientId: patientId);
      final String visitId = await repository.checkIn(
        role: Role.assistant,
        appointmentId: appointmentId,
      );
      await repository.startProgress(
        role: Role.assistant,
        appointmentId: appointmentId,
      );
      return visitId;
    }

    test('creates exactly one Invoice with Items matching the Performed '
        'Treatments exactly, and marks the Visit completed', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final String visitId = await checkInAndStart(patientId);
      final PerformedTreatmentRepositoryImpl treatmentRepository =
          PerformedTreatmentRepositoryImpl(db);

      await treatmentRepository.addTreatment(
        role: Role.assistant,
        actorUserId: 'dentist-1',
        visitId: visitId,
        toothNumber: '18',
        procedureName: 'Filling',
        unitPrice: 50,
        quantity: 2,
      );
      await treatmentRepository.addTreatment(
        role: Role.assistant,
        actorUserId: 'dentist-1',
        visitId: visitId,
        toothNumber: '19',
        procedureName: 'Cleaning',
        unitPrice: 30,
        quantity: 1,
      );

      final String invoiceId = await repository.completeVisit(
        role: Role.assistant,
        actorUserId: 'dentist-1',
        visitId: visitId,
      );

      final List<Invoice> invoices = await db.select(db.invoices).get();
      expect(invoices.length, 1);
      expect(invoices.single.id, invoiceId);
      expect(invoices.single.visitId, visitId);
      expect(invoices.single.patientId, patientId);
      expect(invoices.single.totalAmount, 130);
      expect(invoices.single.status, 'draft');

      final List<InvoiceItemRow> items = await db.select(db.invoiceItems).get();
      expect(items.length, 2);
      expect(items.map((InvoiceItemRow i) => i.description).toSet(), <String>{
        'Filling',
        'Cleaning',
      });
      final InvoiceItemRow fillingItem = items.firstWhere(
        (InvoiceItemRow i) => i.description == 'Filling',
      );
      expect(fillingItem.toothNumber, '18');
      expect(fillingItem.quantity, 2);
      expect(fillingItem.unitPrice, 50);
      expect(fillingItem.totalPrice, 100);

      final Visit visit = await (db.select(
        db.visits,
      )..where((t) => t.id.equals(visitId))).getSingle();
      expect(visit.status, VisitStatus.completed.name);
      expect(visit.endedAt, isNotNull);
    });

    test(
      'throws VisitNotEditableException when the Visit is not in_progress',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final String appointmentId = await seedAppointment(
          patientId: patientId,
        );
        final String visitId = await repository.checkIn(
          role: Role.assistant,
          appointmentId: appointmentId,
        );

        expect(
          () => repository.completeVisit(
            role: Role.assistant,
            actorUserId: 'dentist-1',
            visitId: visitId,
          ),
          throwsA(isA<VisitNotEditableException>()),
        );

        final List<Invoice> invoices = await db.select(db.invoices).get();
        expect(invoices, isEmpty);
      },
    );

    test('throws VisitRequiresTreatmentException when there are no Performed '
        'Treatments', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final String visitId = await checkInAndStart(patientId);

      expect(
        () => repository.completeVisit(
          role: Role.assistant,
          actorUserId: 'dentist-1',
          visitId: visitId,
        ),
        throwsA(isA<VisitRequiresTreatmentException>()),
      );

      final Visit visit = await (db.select(
        db.visits,
      )..where((t) => t.id.equals(visitId))).getSingle();
      expect(visit.status, VisitStatus.inProgress.name);
    });

    test('ignores soft-deleted Performed Treatments', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final String visitId = await checkInAndStart(patientId);
      final PerformedTreatmentRepositoryImpl treatmentRepository =
          PerformedTreatmentRepositoryImpl(db);

      final String removedTreatmentId = await treatmentRepository.addTreatment(
        role: Role.assistant,
        actorUserId: 'dentist-1',
        visitId: visitId,
        toothNumber: '18',
        procedureName: 'Filling',
        unitPrice: 50,
        quantity: 1,
      );
      await treatmentRepository.removeTreatment(
        role: Role.assistant,
        treatmentId: removedTreatmentId,
      );

      expect(
        () => repository.completeVisit(
          role: Role.assistant,
          actorUserId: 'dentist-1',
          visitId: visitId,
        ),
        throwsA(isA<VisitRequiresTreatmentException>()),
      );
    });
  });

  group('VisitRepositoryImpl.unlockVisit', () {
    Future<String> completeAVisit(String patientId) async {
      final String appointmentId = await seedAppointment(patientId: patientId);
      final String visitId = await repository.checkIn(
        role: Role.assistant,
        appointmentId: appointmentId,
      );
      await repository.startProgress(
        role: Role.assistant,
        appointmentId: appointmentId,
      );
      final PerformedTreatmentRepositoryImpl treatmentRepository =
          PerformedTreatmentRepositoryImpl(db);
      await treatmentRepository.addTreatment(
        role: Role.assistant,
        actorUserId: 'dentist-1',
        visitId: visitId,
        toothNumber: '18',
        procedureName: 'Filling',
        unitPrice: 50,
        quantity: 1,
      );
      await repository.completeVisit(
        role: Role.assistant,
        actorUserId: 'dentist-1',
        visitId: visitId,
      );
      return visitId;
    }

    Future<void> setInvoiceStatus(String visitId, String status) async {
      await (db.update(db.invoices)..where((t) => t.visitId.equals(visitId)))
          .write(InvoicesCompanion(status: Value(status)));
    }

    test('transitions the Visit back to in_progress, clears endedAt, and logs '
        'the actor/reason', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final String visitId = await completeAVisit(patientId);

      await repository.unlockVisit(
        role: Role.doctor,
        actorUserId: 'dentist-1',
        visitId: visitId,
        reason: 'Wrong tooth number recorded',
      );

      final Visit visit = await (db.select(
        db.visits,
      )..where((t) => t.id.equals(visitId))).getSingle();
      expect(visit.status, VisitStatus.inProgress.name);
      expect(visit.endedAt, isNull);

      final List<VisitUnlockLog> logs = await db
          .select(db.visitUnlockLogs)
          .get();
      expect(logs.length, 1);
      expect(logs.single.visitId, visitId);
      expect(logs.single.actorUserId, 'dentist-1');
      expect(logs.single.reason, 'Wrong tooth number recorded');
    });

    test(
      'throws VisitNotEditableException when the Visit is not completed',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final String appointmentId = await seedAppointment(
          patientId: patientId,
        );
        final String visitId = await repository.checkIn(
          role: Role.assistant,
          appointmentId: appointmentId,
        );

        expect(
          () => repository.unlockVisit(
            role: Role.doctor,
            actorUserId: 'dentist-1',
            visitId: visitId,
            reason: 'Test reason',
          ),
          throwsA(isA<VisitNotEditableException>()),
        );
      },
    );

    test('throws VisitInvoiceHasPaymentsException when the Invoice is '
        'partially_paid or paid', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final String visitId = await completeAVisit(patientId);
      await setInvoiceStatus(visitId, InvoiceStatus.partiallyPaid.name);

      expect(
        () => repository.unlockVisit(
          role: Role.doctor,
          actorUserId: 'dentist-1',
          visitId: visitId,
          reason: 'Test reason',
        ),
        throwsA(isA<VisitInvoiceHasPaymentsException>()),
      );

      final Visit visit = await (db.select(
        db.visits,
      )..where((t) => t.id.equals(visitId))).getSingle();
      expect(visit.status, VisitStatus.completed.name);
    });

    test(
      'throws VisitInvoiceFinalizedException when the Invoice is voided',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final String visitId = await completeAVisit(patientId);
        await setInvoiceStatus(visitId, InvoiceStatus.voided.name);

        expect(
          () => repository.unlockVisit(
            role: Role.doctor,
            actorUserId: 'dentist-1',
            visitId: visitId,
            reason: 'Test reason',
          ),
          throwsA(isA<VisitInvoiceFinalizedException>()),
        );
      },
    );

    test('succeeds when the Invoice is unpaid (finalized, no payment) and '
        'reverts it back to draft', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final String visitId = await completeAVisit(patientId);
      await setInvoiceStatus(visitId, InvoiceStatus.unpaid.name);

      await repository.unlockVisit(
        role: Role.doctor,
        actorUserId: 'dentist-1',
        visitId: visitId,
        reason: 'Wrong tooth number recorded',
      );

      final Visit visit = await (db.select(
        db.visits,
      )..where((t) => t.id.equals(visitId))).getSingle();
      expect(visit.status, VisitStatus.inProgress.name);

      final Invoice invoice = await (db.select(
        db.invoices,
      )..where((t) => t.visitId.equals(visitId))).getSingle();
      expect(invoice.status, InvoiceStatus.draft.name);
    });

    test('rejects an Assistant with PermissionDeniedException', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final String visitId = await completeAVisit(patientId);

      expect(
        () => repository.unlockVisit(
          role: Role.assistant,
          actorUserId: 'dentist-1',
          visitId: visitId,
          reason: 'Test reason',
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });
}
