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

  /// Completes an `in_progress` Visit: sets status to `completed` and
  /// `ended_at` to UTC now(), locking its Performed Treatments, then
  /// atomically creates exactly one `draft` Invoice linked to the Visit
  /// with one Invoice Item per Performed Treatment (description mirrors
  /// procedure name; tooth number, quantity, unit price, and total price
  /// mirror the treatment). Returns the new Invoice's id.
  ///
  /// Throws [VisitNotEditableException] if the Visit is not `in_progress`.
  /// Throws [VisitRequiresTreatmentException] if it has no Performed
  /// Treatments recorded.
  Future<String> completeVisit({
    required Role role,
    required String actorUserId,
    required String visitId,
  });

  /// Unlocks a `completed` Visit back to `in_progress`, making its Performed
  /// Treatments editable again, and records the unlock with [actorUserId],
  /// a timestamp, and [reason].
  ///
  /// Allowed when the linked Invoice is `draft` or `unpaid` (finalized but
  /// with no payment) — in the `unpaid` case, the Invoice is also reverted
  /// to `draft` as part of the same unlock. Doctor-only.
  ///
  /// Throws [VisitNotEditableException] if the Visit is not `completed`.
  /// Throws [VisitInvoiceHasPaymentsException] if the Invoice has payments
  /// recorded (`partially_paid` or `paid`).
  /// Throws [VisitInvoiceFinalizedException] if the Invoice has been
  /// `voided`.
  Future<void> unlockVisit({
    required Role role,
    required String actorUserId,
    required String visitId,
    required String reason,
  });
}
