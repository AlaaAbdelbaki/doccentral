import 'package:docentral/features/appointment/domain/appointment_exceptions.dart';
import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_repository.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
import 'package:docentral/features/appointment/domain/assignable_user.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/data/database/tables/appointments_table.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_guard.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl(this._db, {Uuid uuid = const Uuid()})
    : _uuid = uuid;

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Stream<List<AppointmentRecord>> watchToday({required Role role}) {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    return watchRange(
      role: role,
      start: startOfDay,
      end: startOfDay.add(const Duration(days: 1)),
    );
  }

  @override
  Stream<List<AppointmentRecord>> watchRange({
    required Role role,
    required DateTime start,
    required DateTime end,
  }) {
    requirePermission(role, Permission.canViewAppointments);

    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _db.select(_db.appointments).join([
            innerJoin(
              _db.patients,
              _db.patients.id.equalsExp(_db.appointments.patientId),
            ),
          ])
          ..where(
            _db.appointments.deletedAt.isNull() &
                _db.appointments.startTime.isBiggerOrEqualValue(start) &
                _db.appointments.startTime.isSmallerThanValue(end),
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

  @override
  Stream<List<AssignableUser>> watchAssignableUsers({required Role role}) {
    requirePermission(role, Permission.canViewAppointments);

    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _db.select(_db.users).join([
          innerJoin(
            _db.userRoles,
            _db.userRoles.userId.equalsExp(_db.users.id),
          ),
          innerJoin(_db.roles, _db.roles.id.equalsExp(_db.userRoles.roleId)),
        ])..where(_db.users.deletedAt.isNull());

    return query.watch().map(
      (List<TypedResult> rows) => rows
          .map((TypedResult row) {
            final User user = row.readTable(_db.users);
            final RoleRow roleRow = row.readTable(_db.roles);
            return AssignableUser(
              id: user.id,
              name: '${user.firstName} ${user.lastName}',
              role: Role.values.byName(roleRow.name),
            );
          })
          .toList(growable: false),
    );
  }

  Future<bool> _hasOverlap({
    required String assignedUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludingAppointmentId,
  }) async {
    final SimpleSelectStatement<$AppointmentsTable, Appointment> select =
        _db.select(_db.appointments)..where(
          (Appointments t) =>
              t.deletedAt.isNull() &
              t.assignedUserId.equals(assignedUserId) &
              t.status.equals(AppointmentStatus.cancelled.name).not() &
              t.startTime.isSmallerThanValue(endTime) &
              t.endTime.isBiggerThanValue(startTime),
        );
    if (excludingAppointmentId != null) {
      select.where(
        (Appointments t) => t.id.equals(excludingAppointmentId).not(),
      );
    }
    final List<Appointment> overlapping = await select.get();
    return overlapping.isNotEmpty;
  }

  @override
  Future<String> createAppointment({
    required Role role,
    required String patientId,
    required String assignedUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
    String? notes,
    bool overrideOverlap = false,
  }) async {
    requirePermission(role, Permission.canManageAppointments);

    if (!overrideOverlap) {
      final bool overlaps = await _hasOverlap(
        assignedUserId: assignedUserId,
        startTime: startTime,
        endTime: endTime,
      );
      if (overlaps) throw const AppointmentOverlapException();
    }

    final String id = _uuid.v4();
    final DateTime now = DateTime.now().toUtc();
    await _db
        .into(_db.appointments)
        .insert(
          AppointmentsCompanion.insert(
            id: id,
            patientId: patientId,
            assignedUserId: assignedUserId,
            startTime: startTime,
            endTime: endTime,
            status: Value(AppointmentStatus.scheduled.name),
            reason: Value(reason?.trim()),
            notes: Value(notes?.trim()),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Future<void> updateAppointment({
    required Role role,
    required String actorUserId,
    required String appointmentId,
    required String assignedUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
    String? notes,
    bool overrideOverlap = false,
  }) async {
    requirePermission(role, Permission.canManageAppointments);

    final String? trimmedReason = reason?.trim();
    final String? trimmedNotes = notes?.trim();

    await _db.transaction(() async {
      final Appointment existing = await (_db.select(
        _db.appointments,
      )..where((Appointments t) => t.id.equals(appointmentId))).getSingle();

      if (existing.status != AppointmentStatus.scheduled.name) {
        throw const AppointmentNotEditableException();
      }

      if (!overrideOverlap) {
        final bool overlaps = await _hasOverlap(
          assignedUserId: assignedUserId,
          startTime: startTime,
          endTime: endTime,
          excludingAppointmentId: appointmentId,
        );
        if (overlaps) throw const AppointmentOverlapException();
      }

      final List<String> changedFields = <String>[
        if (existing.assignedUserId != assignedUserId) 'assignedUserId',
        if (existing.startTime != startTime) 'startTime',
        if (existing.endTime != endTime) 'endTime',
        if (existing.reason != trimmedReason) 'reason',
        if (existing.notes != trimmedNotes) 'notes',
      ];

      final DateTime now = DateTime.now().toUtc();

      await (_db.update(
        _db.appointments,
      )..where((Appointments t) => t.id.equals(appointmentId))).write(
        AppointmentsCompanion(
          assignedUserId: Value(assignedUserId),
          startTime: Value(startTime),
          endTime: Value(endTime),
          reason: Value(trimmedReason),
          notes: Value(trimmedNotes),
          updatedAt: Value(now),
        ),
      );

      if (changedFields.isNotEmpty) {
        await _db
            .into(_db.appointmentEditLogs)
            .insert(
              AppointmentEditLogsCompanion.insert(
                id: _uuid.v4(),
                appointmentId: appointmentId,
                actorUserId: actorUserId,
                changedFields: changedFields.join(','),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
  }
}
