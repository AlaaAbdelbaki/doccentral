import 'package:docentral/features/appointment/domain/appointment_exceptions.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
import 'package:docentral/features/visit/data/visit_repository_impl.dart';
import 'package:docentral/features/visit/domain/visit_exceptions.dart';
import 'package:docentral/features/visit/domain/visit_record.dart';
import 'package:docentral/features/visit/domain/visit_status.dart';
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
}
