import 'package:docentral/features/appointment/data/appointment_repository_impl.dart';
import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
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
}
