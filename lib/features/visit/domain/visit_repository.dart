import 'package:docentral/features/visit/domain/visit_record.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

abstract class VisitRepository {
  /// Checks in a `scheduled` appointment: transitions it to `checked_in`
  /// and creates a linked Visit in `checked_in` status with
  /// `started_at = now()` (UTC). Returns the new Visit's id.
  ///
  /// Throws [AppointmentNotEditableException] if the appointment is not
  /// currently `scheduled`.
  Future<String> checkIn({required Role role, required String appointmentId});

  /// Streams the most recent [limit] visits for [patientId], newest first.
  Stream<List<VisitRecord>> watchRecentVisits({
    required Role role,
    required String patientId,
    int limit = 3,
  });

  /// Streams the Visit linked to [appointmentId], or null if none exists.
  Stream<VisitRecord?> watchVisitForAppointment({
    required Role role,
    required String appointmentId,
  });

  /// Transitions the Visit linked to [appointmentId] from `checked_in` to
  /// `in_progress`, capturing `in_progress_at` as UTC now().
  ///
  /// Throws [VisitNotEditableException] if the Visit is not currently
  /// `checked_in`.
  Future<void> startProgress({
    required Role role,
    required String appointmentId,
  });

  /// Updates the `diagnosis` and `clinical_notes` fields of an `in_progress`
  /// Visit. Intended to be called on field blur (autosave), not gated by a
  /// separate "save" action.
  ///
  /// Throws [VisitNotEditableException] if the Visit is not `in_progress`.
  Future<void> updateClinicalRecord({
    required Role role,
    required String visitId,
    String? diagnosis,
    String? clinicalNotes,
  });
}
