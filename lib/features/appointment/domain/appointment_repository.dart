import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/features/appointment/domain/assignable_user.dart';
import 'package:docentral/features/appointment/domain/cancellation_reason.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment.dart';
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
  /// [plannedTreatmentIds] are linked to the new appointment, transitioning
  /// each from `planned` to `scheduled`.
  ///
  /// Throws [AppointmentOverlapException] if [assignedUserId] already has an
  /// active (non-cancelled) appointment overlapping `[startTime, endTime)`,
  /// unless [overrideOverlap] is true.
  /// Throws [PlannedTreatmentAlreadyBookedException] if any id in
  /// [plannedTreatmentIds] is already linked to a different, non-cancelled
  /// appointment.
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
  });

  /// Updates a `scheduled` appointment's time, assigned user, reason, and
  /// notes. Records an edit-log entry (actor, UTC timestamp, changed field
  /// names) when any field actually changes.
  ///
  /// [plannedTreatmentIds] replaces the appointment's full set of linked
  /// Planned Treatments: newly-linked ones transition `planned` ->
  /// `scheduled`; ones no longer present are unlinked and revert to
  /// `planned`.
  ///
  /// Throws [AppointmentNotEditableException] if the appointment is not
  /// currently `scheduled`. Throws [AppointmentOverlapException] under the
  /// same conditions as [createAppointment], unless [overrideOverlap] is
  /// true. Throws [PlannedTreatmentAlreadyBookedException] under the same
  /// conditions as [createAppointment].
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
  });

  /// Streams the Planned Treatments currently linked to [appointmentId], for
  /// the calendar day-view's planned-treatment summary.
  Stream<List<PlannedTreatment>> watchLinkedPlannedTreatments({
    required Role role,
    required String appointmentId,
  });

  /// Cancels a `scheduled` appointment with a required [reason], freeing its
  /// calendar slot. Records a Cancellation entry (actor, UTC timestamp,
  /// reason).
  ///
  /// [reason] must not be [CancellationReason.rescheduled] — use
  /// [rescheduleAppointment] for that flow instead.
  ///
  /// Throws [AppointmentNotEditableException] if the appointment is not
  /// currently `scheduled`.
  Future<void> cancelAppointment({
    required Role role,
    required String actorUserId,
    required String appointmentId,
    required CancellationReason reason,
  });

  /// Atomically creates a replacement appointment and cancels
  /// [appointmentId] (reason [CancellationReason.rescheduled]), linking both
  /// via `rescheduledToAppointmentId`. The original appointment is cancelled
  /// only if the replacement is created successfully.
  ///
  /// Throws [AppointmentNotEditableException] if [appointmentId] is not
  /// currently `scheduled`. Throws [AppointmentOverlapException] under the
  /// same conditions as [createAppointment] for the replacement's time slot,
  /// unless [overrideOverlap] is true.
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
  });

  /// Number of `no_show` cancellations ever recorded for [patientId].
  Stream<int> watchNoShowCount({required Role role, required String patientId});
}
