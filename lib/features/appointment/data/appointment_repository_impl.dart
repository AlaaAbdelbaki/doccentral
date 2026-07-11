import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_repository.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_guard.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<AppointmentRecord>> watchToday({required Role role}) {
    requirePermission(role, Permission.canViewAppointments);

    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _db.select(_db.appointments).join([
            innerJoin(
              _db.patients,
              _db.patients.id.equalsExp(_db.appointments.patientId),
            ),
          ])
          ..where(
            _db.appointments.deletedAt.isNull() &
                _db.appointments.startTime.isBiggerOrEqualValue(startOfDay) &
                _db.appointments.startTime.isSmallerThanValue(endOfDay),
          )
          ..orderBy([OrderingTerm.asc(_db.appointments.startTime)]);

    return query.watch().map(
      (List<TypedResult> rows) => rows.map(_toRecord).toList(growable: false),
    );
  }

  AppointmentRecord _toRecord(TypedResult row) {
    final Appointment appointment = row.readTable(_db.appointments);
    final Patient patient = row.readTable(_db.patients);
    return AppointmentRecord(
      id: appointment.id,
      patientId: appointment.patientId,
      patientName: '${patient.firstName} ${patient.lastName}',
      assignedUserId: appointment.assignedUserId,
      startTime: appointment.startTime,
      endTime: appointment.endTime,
      status: AppointmentStatus.values.byName(appointment.status),
      reason: appointment.reason,
      notes: appointment.notes,
    );
  }
}
