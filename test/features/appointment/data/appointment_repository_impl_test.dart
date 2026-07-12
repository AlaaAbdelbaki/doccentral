import 'package:docentral/features/appointment/data/appointment_repository_impl.dart';
import 'package:docentral/features/appointment/domain/appointment_exceptions.dart';
import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
import 'package:docentral/features/appointment/domain/assignable_user.dart';
import 'package:docentral/features/appointment/domain/cancellation_reason.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment.dart';
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
  late AppointmentRepositoryImpl repository;
  const Uuid uuid = Uuid();

  setUp(() {
    db = _createInMemoryDatabase();
    repository = AppointmentRepositoryImpl(db);
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

  Future<String> seedUser({
    required String firstName,
    required String lastName,
    required Role role,
  }) async {
    final String userId = uuid.v4();
    final String roleId = uuid.v4();
    final DateTime now = DateTime.now();
    const String clinicId = 'clinic-1';
    await db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            id: userId,
            clinicId: clinicId,
            firstName: firstName,
            lastName: lastName,
            email: '$firstName@example.com',
            authUserId: 'auth-$userId',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.roles)
        .insert(
          RolesCompanion.insert(
            id: roleId,
            clinicId: clinicId,
            name: role.name,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.userRoles)
        .insert(
          UserRolesCompanion.insert(
            id: uuid.v4(),
            userId: userId,
            roleId: roleId,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return userId;
  }

  Future<String> seedPlannedTreatment({
    required String patientId,
    String status = 'planned',
  }) async {
    final String id = uuid.v4();
    final DateTime now = DateTime.now();
    await db
        .into(db.plannedTreatments)
        .insert(
          PlannedTreatmentsCompanion.insert(
            id: id,
            patientId: patientId,
            procedureName: 'Root canal',
            toothNumber: '14',
            estimatedUnitPrice: 250,
            sequenceNumber: 1,
            status: Value(status),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<String> seedAppointment({
    required String patientId,
    required DateTime startTime,
    String status = 'scheduled',
    String? reason,
    DateTime? deletedAt,
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
            startTime: startTime,
            endTime: startTime.add(const Duration(minutes: 30)),
            status: Value(status),
            reason: Value(reason),
            createdAt: now,
            updatedAt: now,
            deletedAt: Value(deletedAt),
          ),
        );
    return id;
  }

  group('AppointmentRepositoryImpl.watchToday', () {
    test('returns only today\'s appointments in chronological order', () async {
      final String patientA = await seedPatient('Amine', 'Trabelsi');
      final String patientB = await seedPatient('Sarra', 'Ben Youssef');
      final DateTime now = DateTime.now();
      final DateTime today9am = DateTime(now.year, now.month, now.day, 9);
      final DateTime today14pm = DateTime(now.year, now.month, now.day, 14);
      final DateTime yesterday = today9am.subtract(const Duration(days: 1));
      final DateTime tomorrow = today9am.add(const Duration(days: 1));

      await seedAppointment(
        patientId: patientB,
        startTime: today14pm,
        reason: 'Follow-up',
      );
      await seedAppointment(
        patientId: patientA,
        startTime: today9am,
        reason: 'Cleaning',
      );
      await seedAppointment(patientId: patientA, startTime: yesterday);
      await seedAppointment(patientId: patientA, startTime: tomorrow);

      final List<AppointmentRecord> appointments = await repository
          .watchToday(role: Role.assistant)
          .first;

      expect(appointments.length, 2);
      expect(appointments.first.patientName, 'Amine Trabelsi');
      expect(appointments.first.reason, 'Cleaning');
      expect(appointments.last.patientName, 'Sarra Ben Youssef');
    });

    test('excludes soft-deleted appointments', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final DateTime now = DateTime.now();
      final DateTime today9am = DateTime(now.year, now.month, now.day, 9);

      await seedAppointment(
        patientId: patientId,
        startTime: today9am,
        deletedAt: now,
      );

      final List<AppointmentRecord> appointments = await repository
          .watchToday(role: Role.assistant)
          .first;

      expect(appointments, isEmpty);
    });

    test('maps the stored status string to AppointmentStatus', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final DateTime now = DateTime.now();
      final DateTime today9am = DateTime(now.year, now.month, now.day, 9);

      await seedAppointment(
        patientId: patientId,
        startTime: today9am,
        status: 'checkedIn',
      );

      final List<AppointmentRecord> appointments = await repository
          .watchToday(role: Role.assistant)
          .first;

      expect(appointments.single.status, AppointmentStatus.checkedIn);
    });
  });

  group('AppointmentRepositoryImpl.watchRange', () {
    test('returns appointments within [start, end) only', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final DateTime start = DateTime(2026, 6, 8);
      final DateTime end = start.add(const Duration(days: 7));

      await seedAppointment(
        patientId: patientId,
        startTime: DateTime(2026, 6, 7, 23, 59),
      );
      await seedAppointment(
        patientId: patientId,
        startTime: DateTime(2026, 6, 8, 9),
      );
      await seedAppointment(
        patientId: patientId,
        startTime: DateTime(2026, 6, 14, 17),
      );
      await seedAppointment(
        patientId: patientId,
        startTime: DateTime(2026, 6, 15),
      );

      final List<AppointmentRecord> appointments = await repository
          .watchRange(role: Role.assistant, start: start, end: end)
          .first;

      expect(appointments.length, 2);
      expect(appointments.first.startTime, DateTime(2026, 6, 8, 9));
      expect(appointments.last.startTime, DateTime(2026, 6, 14, 17));
    });
  });

  group('AppointmentRepositoryImpl.watchAssignableUsers', () {
    test('returns users with their role, excluding deleted users', () async {
      final String dentistId = await seedUser(
        firstName: 'Sami',
        lastName: 'Gharbi',
        role: Role.doctor,
      );
      await seedUser(
        firstName: 'Nour',
        lastName: 'Jlassi',
        role: Role.assistant,
      );

      final List<AssignableUser> users = await repository
          .watchAssignableUsers(role: Role.assistant)
          .first;

      expect(users.length, 2);
      final AssignableUser dentist = users.firstWhere(
        (AssignableUser u) => u.id == dentistId,
      );
      expect(dentist.name, 'Sami Gharbi');
      expect(dentist.role, Role.doctor);
    });
  });

  group('AppointmentRepositoryImpl.createAppointment', () {
    test('creates a scheduled appointment', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final DateTime start = DateTime(2026, 6, 8, 9);

      final String id = await repository.createAppointment(
        role: Role.assistant,
        patientId: patientId,
        assignedUserId: 'dentist-1',
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
        reason: 'Cleaning',
      );

      final List<AppointmentRecord> appointments = await repository
          .watchRange(
            role: Role.assistant,
            start: start,
            end: start.add(const Duration(days: 1)),
          )
          .first;
      expect(appointments.single.id, id);
      expect(appointments.single.status, AppointmentStatus.scheduled);
    });

    test(
      'throws AppointmentOverlapException for the same assigned user without override',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final DateTime start = DateTime(2026, 6, 8, 9);
        await seedAppointment(patientId: patientId, startTime: start);

        expect(
          () => repository.createAppointment(
            role: Role.assistant,
            patientId: patientId,
            assignedUserId: 'dentist-1',
            startTime: start.add(const Duration(minutes: 15)),
            endTime: start.add(const Duration(minutes: 45)),
          ),
          throwsA(isA<AppointmentOverlapException>()),
        );
      },
    );

    test('creates the appointment when overrideOverlap is true', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final DateTime start = DateTime(2026, 6, 8, 9);
      await seedAppointment(patientId: patientId, startTime: start);

      final String id = await repository.createAppointment(
        role: Role.assistant,
        patientId: patientId,
        assignedUserId: 'dentist-1',
        startTime: start.add(const Duration(minutes: 15)),
        endTime: start.add(const Duration(minutes: 45)),
        overrideOverlap: true,
      );

      final List<AppointmentRecord> appointments = await repository
          .watchRange(
            role: Role.assistant,
            start: start,
            end: start.add(const Duration(days: 1)),
          )
          .first;
      expect(appointments.length, 2);
      expect(appointments.any((AppointmentRecord a) => a.id == id), isTrue);
    });

    test(
      'does not treat overlap with a different assigned user as a conflict',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final DateTime start = DateTime(2026, 6, 8, 9);
        await seedAppointment(patientId: patientId, startTime: start);

        final String id = await repository.createAppointment(
          role: Role.assistant,
          patientId: patientId,
          assignedUserId: 'dentist-2',
          startTime: start,
          endTime: start.add(const Duration(minutes: 30)),
        );

        expect(id, isNotEmpty);
      },
    );

    test(
      'does not treat overlap with a cancelled appointment as a conflict',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final DateTime start = DateTime(2026, 6, 8, 9);
        await seedAppointment(
          patientId: patientId,
          startTime: start,
          status: 'cancelled',
        );

        final String id = await repository.createAppointment(
          role: Role.assistant,
          patientId: patientId,
          assignedUserId: 'dentist-1',
          startTime: start,
          endTime: start.add(const Duration(minutes: 30)),
        );

        expect(id, isNotEmpty);
      },
    );
  });

  group('AppointmentRepositoryImpl.updateAppointment', () {
    test(
      'creates an edit log entry with the correct actor and changed fields',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final DateTime start = DateTime(2026, 6, 8, 9);
        final String id = await seedAppointment(
          patientId: patientId,
          startTime: start,
          reason: 'Cleaning',
        );

        await repository.updateAppointment(
          role: Role.assistant,
          actorUserId: 'actor-1',
          appointmentId: id,
          assignedUserId: 'dentist-2',
          startTime: start,
          endTime: start.add(const Duration(minutes: 30)),
          reason: 'Cleaning',
        );

        final List<AppointmentEditLog> logs = await db
            .select(db.appointmentEditLogs)
            .get();
        expect(logs.length, 1);
        expect(logs.first.appointmentId, id);
        expect(logs.first.actorUserId, 'actor-1');
        expect(logs.first.changedFields, 'assignedUserId');
      },
    );

    test('does not create an edit log entry when nothing changes', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final DateTime start = DateTime(2026, 6, 8, 9);
      final String id = await seedAppointment(
        patientId: patientId,
        startTime: start,
      );

      await repository.updateAppointment(
        role: Role.assistant,
        actorUserId: 'actor-1',
        appointmentId: id,
        assignedUserId: 'dentist-1',
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
      );

      final List<AppointmentEditLog> logs = await db
          .select(db.appointmentEditLogs)
          .get();
      expect(logs, isEmpty);
    });

    test(
      'throws AppointmentNotEditableException for a non-scheduled appointment',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final DateTime start = DateTime(2026, 6, 8, 9);
        final String id = await seedAppointment(
          patientId: patientId,
          startTime: start,
          status: 'checkedIn',
        );

        expect(
          () => repository.updateAppointment(
            role: Role.assistant,
            actorUserId: 'actor-1',
            appointmentId: id,
            assignedUserId: 'dentist-1',
            startTime: start,
            endTime: start.add(const Duration(minutes: 45)),
          ),
          throwsA(isA<AppointmentNotEditableException>()),
        );
      },
    );

    test(
      'throws AppointmentOverlapException when the new time overlaps another appointment for the same user',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final DateTime start = DateTime(2026, 6, 8, 9);
        final String editableId = await seedAppointment(
          patientId: patientId,
          startTime: start,
        );
        await seedAppointment(
          patientId: patientId,
          startTime: start.add(const Duration(hours: 2)),
        );

        expect(
          () => repository.updateAppointment(
            role: Role.assistant,
            actorUserId: 'actor-1',
            appointmentId: editableId,
            assignedUserId: 'dentist-1',
            startTime: start.add(const Duration(hours: 2, minutes: 10)),
            endTime: start.add(const Duration(hours: 2, minutes: 40)),
          ),
          throwsA(isA<AppointmentOverlapException>()),
        );
      },
    );
  });

  group('AppointmentRepositoryImpl.cancelAppointment', () {
    test(
      'creates a Cancellation record with non-null reason, actor, and timestamp, and frees the slot',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final DateTime start = DateTime(2026, 6, 8, 9);
        final String id = await seedAppointment(
          patientId: patientId,
          startTime: start,
        );

        await repository.cancelAppointment(
          role: Role.assistant,
          actorUserId: 'actor-1',
          appointmentId: id,
          reason: CancellationReason.noShow,
        );

        final Appointment appointment = await (db.select(
          db.appointments,
        )..where((t) => t.id.equals(id))).getSingle();
        expect(appointment.status, AppointmentStatus.cancelled.name);

        final List<AppointmentCancellation> cancellations = await db
            .select(db.appointmentCancellations)
            .get();
        expect(cancellations.length, 1);
        expect(cancellations.first.appointmentId, id);
        expect(cancellations.first.actorUserId, 'actor-1');
        expect(cancellations.first.reason, CancellationReason.noShow.name);
        expect(cancellations.first.createdAt, isNotNull);
      },
    );

    test(
      'the cancelled slot no longer overlaps a new appointment for the same user',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final DateTime start = DateTime(2026, 6, 8, 9);
        final String id = await seedAppointment(
          patientId: patientId,
          startTime: start,
        );

        await repository.cancelAppointment(
          role: Role.assistant,
          actorUserId: 'actor-1',
          appointmentId: id,
          reason: CancellationReason.patientCancelled,
        );

        final String newId = await repository.createAppointment(
          role: Role.assistant,
          patientId: patientId,
          assignedUserId: 'dentist-1',
          startTime: start,
          endTime: start.add(const Duration(minutes: 30)),
        );

        expect(newId, isNotEmpty);
      },
    );

    test(
      'throws AppointmentNotEditableException for a non-scheduled appointment',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final DateTime start = DateTime(2026, 6, 8, 9);
        final String id = await seedAppointment(
          patientId: patientId,
          startTime: start,
          status: 'completed',
        );

        expect(
          () => repository.cancelAppointment(
            role: Role.assistant,
            actorUserId: 'actor-1',
            appointmentId: id,
            reason: CancellationReason.noShow,
          ),
          throwsA(isA<AppointmentNotEditableException>()),
        );
      },
    );
  });

  group('AppointmentRepositoryImpl.rescheduleAppointment', () {
    test(
      'creates a replacement appointment, cancels the original, and links both',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final DateTime start = DateTime(2026, 6, 8, 9);
        final String originalId = await seedAppointment(
          patientId: patientId,
          startTime: start,
        );

        final String newId = await repository.rescheduleAppointment(
          role: Role.assistant,
          actorUserId: 'actor-1',
          appointmentId: originalId,
          newAssignedUserId: 'dentist-2',
          newStartTime: start.add(const Duration(days: 1)),
          newEndTime: start.add(const Duration(days: 1, minutes: 30)),
        );

        final Appointment original = await (db.select(
          db.appointments,
        )..where((t) => t.id.equals(originalId))).getSingle();
        expect(original.status, AppointmentStatus.cancelled.name);
        expect(original.rescheduledToAppointmentId, newId);

        final Appointment replacement = await (db.select(
          db.appointments,
        )..where((t) => t.id.equals(newId))).getSingle();
        expect(replacement.status, AppointmentStatus.scheduled.name);
        expect(replacement.assignedUserId, 'dentist-2');
        expect(replacement.patientId, patientId);

        final List<AppointmentCancellation> cancellations = await db
            .select(db.appointmentCancellations)
            .get();
        expect(
          cancellations.single.reason,
          CancellationReason.rescheduled.name,
        );
      },
    );

    test(
      'does not cancel the original when the replacement overlaps without override',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final DateTime start = DateTime(2026, 6, 8, 9);
        final String originalId = await seedAppointment(
          patientId: patientId,
          startTime: start,
        );
        await seedAppointment(
          patientId: patientId,
          startTime: start.add(const Duration(days: 1)),
        );

        await expectLater(
          repository.rescheduleAppointment(
            role: Role.assistant,
            actorUserId: 'actor-1',
            appointmentId: originalId,
            newAssignedUserId: 'dentist-1',
            newStartTime: start.add(const Duration(days: 1)),
            newEndTime: start.add(const Duration(days: 1, minutes: 30)),
          ),
          throwsA(isA<AppointmentOverlapException>()),
        );

        final Appointment original = await (db.select(
          db.appointments,
        )..where((t) => t.id.equals(originalId))).getSingle();
        expect(original.status, AppointmentStatus.scheduled.name);
      },
    );

    test(
      'throws AppointmentNotEditableException for a non-scheduled original',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final DateTime start = DateTime(2026, 6, 8, 9);
        final String originalId = await seedAppointment(
          patientId: patientId,
          startTime: start,
          status: 'cancelled',
        );

        expect(
          () => repository.rescheduleAppointment(
            role: Role.assistant,
            actorUserId: 'actor-1',
            appointmentId: originalId,
            newAssignedUserId: 'dentist-1',
            newStartTime: start.add(const Duration(days: 1)),
            newEndTime: start.add(const Duration(days: 1, minutes: 30)),
          ),
          throwsA(isA<AppointmentNotEditableException>()),
        );
      },
    );
  });

  group('AppointmentRepositoryImpl.watchNoShowCount', () {
    test('counts only no_show cancellations for the given patient', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final String otherPatientId = await seedPatient('Sarra', 'Ben Youssef');
      final DateTime start = DateTime(2026, 6, 8, 9);

      final String a = await seedAppointment(
        patientId: patientId,
        startTime: start,
      );
      final String b = await seedAppointment(
        patientId: patientId,
        startTime: start.add(const Duration(days: 1)),
      );
      final String c = await seedAppointment(
        patientId: patientId,
        startTime: start.add(const Duration(days: 2)),
      );
      final String d = await seedAppointment(
        patientId: otherPatientId,
        startTime: start.add(const Duration(days: 3)),
      );

      await repository.cancelAppointment(
        role: Role.assistant,
        actorUserId: 'actor-1',
        appointmentId: a,
        reason: CancellationReason.noShow,
      );
      await repository.cancelAppointment(
        role: Role.assistant,
        actorUserId: 'actor-1',
        appointmentId: b,
        reason: CancellationReason.noShow,
      );
      await repository.cancelAppointment(
        role: Role.assistant,
        actorUserId: 'actor-1',
        appointmentId: c,
        reason: CancellationReason.patientCancelled,
      );
      await repository.cancelAppointment(
        role: Role.assistant,
        actorUserId: 'actor-1',
        appointmentId: d,
        reason: CancellationReason.noShow,
      );

      final int count = await repository
          .watchNoShowCount(role: Role.assistant, patientId: patientId)
          .first;

      expect(count, 2);
    });
  });

  group('AppointmentRepositoryImpl planned-treatment linking', () {
    test(
      'createAppointment with plannedTreatmentIds links them and marks them scheduled',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final String treatmentId = await seedPlannedTreatment(
          patientId: patientId,
        );
        final DateTime start = DateTime(2026, 6, 8, 9);

        final String appointmentId = await repository.createAppointment(
          role: Role.assistant,
          patientId: patientId,
          assignedUserId: 'dentist-1',
          startTime: start,
          endTime: start.add(const Duration(minutes: 30)),
          plannedTreatmentIds: <String>[treatmentId],
        );

        final List<PlannedTreatment> linked = await repository
            .watchLinkedPlannedTreatments(
              role: Role.assistant,
              appointmentId: appointmentId,
            )
            .first;
        expect(linked.single.id, treatmentId);

        final PlannedTreatmentRow treatment = await (db.select(
          db.plannedTreatments,
        )..where((t) => t.id.equals(treatmentId))).getSingle();
        expect(treatment.status, 'scheduled');
      },
    );

    test(
      'createAppointment throws PlannedTreatmentAlreadyBookedException when '
      'the treatment is already linked to another non-cancelled appointment',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final String treatmentId = await seedPlannedTreatment(
          patientId: patientId,
        );
        final DateTime start = DateTime(2026, 6, 8, 9);
        await repository.createAppointment(
          role: Role.assistant,
          patientId: patientId,
          assignedUserId: 'dentist-1',
          startTime: start,
          endTime: start.add(const Duration(minutes: 30)),
          plannedTreatmentIds: <String>[treatmentId],
        );

        expect(
          () => repository.createAppointment(
            role: Role.assistant,
            patientId: patientId,
            assignedUserId: 'dentist-2',
            startTime: start.add(const Duration(hours: 2)),
            endTime: start.add(const Duration(hours: 2, minutes: 30)),
            plannedTreatmentIds: <String>[treatmentId],
          ),
          throwsA(isA<PlannedTreatmentAlreadyBookedException>()),
        );
      },
    );

    test(
      'updateAppointment removing a link reverts the treatment to planned',
      () async {
        final String patientId = await seedPatient('Amine', 'Trabelsi');
        final String treatmentId = await seedPlannedTreatment(
          patientId: patientId,
        );
        final DateTime start = DateTime(2026, 6, 8, 9);
        final String appointmentId = await repository.createAppointment(
          role: Role.assistant,
          patientId: patientId,
          assignedUserId: 'dentist-1',
          startTime: start,
          endTime: start.add(const Duration(minutes: 30)),
          plannedTreatmentIds: <String>[treatmentId],
        );

        await repository.updateAppointment(
          role: Role.assistant,
          actorUserId: 'actor-1',
          appointmentId: appointmentId,
          assignedUserId: 'dentist-1',
          startTime: start,
          endTime: start.add(const Duration(minutes: 30)),
        );

        final List<PlannedTreatment> linked = await repository
            .watchLinkedPlannedTreatments(
              role: Role.assistant,
              appointmentId: appointmentId,
            )
            .first;
        expect(linked, isEmpty);

        final PlannedTreatmentRow treatment = await (db.select(
          db.plannedTreatments,
        )..where((t) => t.id.equals(treatmentId))).getSingle();
        expect(treatment.status, 'planned');
      },
    );

    test('updateAppointment can add a new link', () async {
      final String patientId = await seedPatient('Amine', 'Trabelsi');
      final String treatmentId = await seedPlannedTreatment(
        patientId: patientId,
      );
      final DateTime start = DateTime(2026, 6, 8, 9);
      final String appointmentId = await repository.createAppointment(
        role: Role.assistant,
        patientId: patientId,
        assignedUserId: 'dentist-1',
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
      );

      await repository.updateAppointment(
        role: Role.assistant,
        actorUserId: 'actor-1',
        appointmentId: appointmentId,
        assignedUserId: 'dentist-1',
        startTime: start,
        endTime: start.add(const Duration(minutes: 30)),
        plannedTreatmentIds: <String>[treatmentId],
      );

      final List<PlannedTreatment> linked = await repository
          .watchLinkedPlannedTreatments(
            role: Role.assistant,
            appointmentId: appointmentId,
          )
          .first;
      expect(linked.single.id, treatmentId);
    });
  });
}
