import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/assignable_user.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

abstract class AppointmentRepository {
  /// Streams today's (local device date) appointments in chronological
  /// (start time) order, excluding soft-deleted rows.
  Stream<List<AppointmentRecord>> watchToday({required Role role});

  /// Streams appointments with a start time in `[start, end)`, in
  /// chronological order, excluding soft-deleted rows.
  Stream<List<AppointmentRecord>> watchRange({
    required Role role,
    required DateTime start,
    required DateTime end,
  });

  /// Streams staff (Users) who can be assigned to an appointment.
  Stream<List<AssignableUser>> watchAssignableUsers({required Role role});

  /// Creates a new appointment in `scheduled` status.
  ///
  /// Throws [AppointmentOverlapException] if [assignedUserId] already has an
  /// active (non-cancelled) appointment overlapping `[startTime, endTime)`,
  /// unless [overrideOverlap] is true.
  Future<String> createAppointment({
    required Role role,
    required String patientId,
    required String assignedUserId,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
    String? notes,
    bool overrideOverlap = false,
  });

  /// Updates a `scheduled` appointment's time, assigned user, reason, and
  /// notes. Records an edit-log entry (actor, UTC timestamp, changed field
  /// names) when any field actually changes.
  ///
  /// Throws [AppointmentNotEditableException] if the appointment is not
  /// currently `scheduled`. Throws [AppointmentOverlapException] under the
  /// same conditions as [createAppointment], unless [overrideOverlap] is
  /// true.
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
  });
}
