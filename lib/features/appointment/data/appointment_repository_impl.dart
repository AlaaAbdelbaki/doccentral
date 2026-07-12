import 'package:docentral/features/appointment/domain/appointment_exceptions.dart';
import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/appointment_repository.dart';
import 'package:docentral/features/appointment/domain/appointment_status.dart';
import 'package:docentral/features/appointment/domain/assignable_user.dart';
import 'package:docentral/features/appointment/domain/cancellation_reason.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment_status.dart';
import 'package:docentral/shared/data/database/app_database.dart';
import 'package:docentral/shared/data/database/tables/appointment_planned_treatments_table.dart';
import 'package:docentral/shared/data/database/tables/appointments_table.dart';
import 'package:docentral/shared/data/database/tables/planned_treatments_table.dart';
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
    List<String> plannedTreatmentIds = const <String>[],
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

    return _db.transaction(() async {
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

      for (final String plannedTreatmentId in plannedTreatmentIds) {
        await _linkPlannedTreatment(
          appointmentId: id,
          plannedTreatmentId: plannedTreatmentId,
        );
      }

      return id;
    });
  }

  /// Throws [PlannedTreatmentAlreadyBookedException] if
  /// [plannedTreatmentId] is already linked to a different, non-cancelled
  /// appointment. Must run inside a transaction.
  Future<void> _linkPlannedTreatment({
    required String appointmentId,
    required String plannedTreatmentId,
  }) async {
    final JoinedSelectStatement<HasResultSet, dynamic> existingLinkQuery =
        _db.select(_db.appointmentPlannedTreatments).join([
          innerJoin(
            _db.appointments,
            _db.appointments.id.equalsExp(
              _db.appointmentPlannedTreatments.appointmentId,
            ),
          ),
        ])..where(
          _db.appointmentPlannedTreatments.plannedTreatmentId.equals(
                plannedTreatmentId,
              ) &
              _db.appointments.status
                  .equals(AppointmentStatus.cancelled.name)
                  .not() &
              _db.appointmentPlannedTreatments.appointmentId
                  .equals(appointmentId)
                  .not(),
        );
    final bool alreadyBooked = (await existingLinkQuery.get()).isNotEmpty;
    if (alreadyBooked) throw const PlannedTreatmentAlreadyBookedException();

    final DateTime now = DateTime.now().toUtc();
    await _db
        .into(_db.appointmentPlannedTreatments)
        .insert(
          AppointmentPlannedTreatmentsCompanion.insert(
            id: _uuid.v4(),
            appointmentId: appointmentId,
            plannedTreatmentId: plannedTreatmentId,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await (_db.update(
      _db.plannedTreatments,
    )..where((PlannedTreatments t) => t.id.equals(plannedTreatmentId))).write(
      PlannedTreatmentsCompanion(
        status: Value(PlannedTreatmentStatus.scheduled.name),
        updatedAt: Value(now),
      ),
    );
  }

  /// Must run inside a transaction.
  Future<void> _unlinkPlannedTreatment({
    required String appointmentId,
    required String plannedTreatmentId,
  }) async {
    await (_db.delete(_db.appointmentPlannedTreatments)..where(
          (AppointmentPlannedTreatments t) =>
              t.appointmentId.equals(appointmentId) &
              t.plannedTreatmentId.equals(plannedTreatmentId),
        ))
        .go();

    final DateTime now = DateTime.now().toUtc();
    await (_db.update(
      _db.plannedTreatments,
    )..where((PlannedTreatments t) => t.id.equals(plannedTreatmentId))).write(
      PlannedTreatmentsCompanion(
        status: Value(PlannedTreatmentStatus.planned.name),
        updatedAt: Value(now),
      ),
    );
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
    List<String> plannedTreatmentIds = const <String>[],
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

      final List<AppointmentPlannedTreatment> currentLinks =
          await (_db.select(_db.appointmentPlannedTreatments)..where(
                (AppointmentPlannedTreatments t) =>
                    t.appointmentId.equals(appointmentId),
              ))
              .get();
      final Set<String> currentIds = currentLinks
          .map((AppointmentPlannedTreatment link) => link.plannedTreatmentId)
          .toSet();
      final Set<String> newIds = plannedTreatmentIds.toSet();

      for (final String toRemove in currentIds.difference(newIds)) {
        await _unlinkPlannedTreatment(
          appointmentId: appointmentId,
          plannedTreatmentId: toRemove,
        );
      }
      for (final String toAdd in newIds.difference(currentIds)) {
        await _linkPlannedTreatment(
          appointmentId: appointmentId,
          plannedTreatmentId: toAdd,
        );
      }
    });
  }

  @override
  Future<void> cancelAppointment({
    required Role role,
    required String actorUserId,
    required String appointmentId,
    required CancellationReason reason,
  }) async {
    assert(
      reason != CancellationReason.rescheduled,
      'Use rescheduleAppointment for CancellationReason.rescheduled',
    );
    requirePermission(role, Permission.canManageAppointments);

    await _db.transaction(() async {
      await _cancel(
        appointmentId: appointmentId,
        actorUserId: actorUserId,
        reason: reason,
      );
    });
  }

  /// Validates the appointment is `scheduled`, marks it `cancelled`, and
  /// inserts a Cancellation record. Must run inside a transaction.
  Future<void> _cancel({
    required String appointmentId,
    required String actorUserId,
    required CancellationReason reason,
    String? rescheduledToAppointmentId,
  }) async {
    final Appointment existing = await (_db.select(
      _db.appointments,
    )..where((Appointments t) => t.id.equals(appointmentId))).getSingle();

    if (existing.status != AppointmentStatus.scheduled.name) {
      throw const AppointmentNotEditableException();
    }

    final DateTime now = DateTime.now().toUtc();

    await (_db.update(
      _db.appointments,
    )..where((Appointments t) => t.id.equals(appointmentId))).write(
      AppointmentsCompanion(
        status: Value(AppointmentStatus.cancelled.name),
        rescheduledToAppointmentId: Value(rescheduledToAppointmentId),
        updatedAt: Value(now),
      ),
    );

    await _db
        .into(_db.appointmentCancellations)
        .insert(
          AppointmentCancellationsCompanion.insert(
            id: _uuid.v4(),
            appointmentId: appointmentId,
            actorUserId: actorUserId,
            reason: reason.name,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<String> rescheduleAppointment({
    required Role role,
    required String actorUserId,
    required String appointmentId,
    required String newAssignedUserId,
    required DateTime newStartTime,
    required DateTime newEndTime,
    String? newReason,
    String? newNotes,
    bool overrideOverlap = false,
  }) async {
    requirePermission(role, Permission.canManageAppointments);

    if (!overrideOverlap) {
      final bool overlaps = await _hasOverlap(
        assignedUserId: newAssignedUserId,
        startTime: newStartTime,
        endTime: newEndTime,
      );
      if (overlaps) throw const AppointmentOverlapException();
    }

    return _db.transaction(() async {
      final Appointment original = await (_db.select(
        _db.appointments,
      )..where((Appointments t) => t.id.equals(appointmentId))).getSingle();

      if (original.status != AppointmentStatus.scheduled.name) {
        throw const AppointmentNotEditableException();
      }

      final String newId = _uuid.v4();
      final DateTime now = DateTime.now().toUtc();

      await _db
          .into(_db.appointments)
          .insert(
            AppointmentsCompanion.insert(
              id: newId,
              patientId: original.patientId,
              assignedUserId: newAssignedUserId,
              startTime: newStartTime,
              endTime: newEndTime,
              status: Value(AppointmentStatus.scheduled.name),
              reason: Value(newReason?.trim()),
              notes: Value(newNotes?.trim()),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await _cancel(
        appointmentId: appointmentId,
        actorUserId: actorUserId,
        reason: CancellationReason.rescheduled,
        rescheduledToAppointmentId: newId,
      );

      return newId;
    });
  }

  @override
  Stream<int> watchNoShowCount({
    required Role role,
    required String patientId,
  }) {
    requirePermission(role, Permission.canViewAppointments);

    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _db.select(_db.appointmentCancellations).join([
          innerJoin(
            _db.appointments,
            _db.appointments.id.equalsExp(
              _db.appointmentCancellations.appointmentId,
            ),
          ),
        ])..where(
          _db.appointments.patientId.equals(patientId) &
              _db.appointmentCancellations.reason.equals(
                CancellationReason.noShow.name,
              ),
        );

    return query.watch().map((List<TypedResult> rows) => rows.length);
  }

  @override
  Stream<List<PlannedTreatment>> watchLinkedPlannedTreatments({
    required Role role,
    required String appointmentId,
  }) {
    requirePermission(role, Permission.canViewAppointments);

    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _db.select(_db.appointmentPlannedTreatments).join([
          innerJoin(
            _db.plannedTreatments,
            _db.plannedTreatments.id.equalsExp(
              _db.appointmentPlannedTreatments.plannedTreatmentId,
            ),
          ),
        ])..where(
          _db.appointmentPlannedTreatments.appointmentId.equals(appointmentId),
        );

    return query.watch().map(
      (List<TypedResult> rows) => rows
          .map((TypedResult row) {
            final PlannedTreatmentRow treatment = row.readTable(
              _db.plannedTreatments,
            );
            return PlannedTreatment(
              id: treatment.id,
              patientId: treatment.patientId,
              procedureName: treatment.procedureName,
              toothNumber: treatment.toothNumber,
              estimatedUnitPrice: treatment.estimatedUnitPrice,
              sequenceNumber: treatment.sequenceNumber,
              status: PlannedTreatmentStatus.values.byName(treatment.status),
              targetDate: treatment.targetDate,
            );
          })
          .toList(growable: false),
    );
  }
}
