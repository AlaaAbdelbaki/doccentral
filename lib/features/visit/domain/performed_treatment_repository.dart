import 'package:docentral/features/visit/domain/performed_treatment.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

abstract class PerformedTreatmentRepository {
  /// Streams Performed Treatments for [visitId], oldest first.
  Stream<List<PerformedTreatment>> watchForVisit({
    required Role role,
    required String visitId,
  });

  /// Adds a Performed Treatment to an `in_progress` Visit, timestamped and
  /// attributed to [actorUserId]. Returns the new treatment's id.
  ///
  /// Throws [VisitNotEditableException] if the Visit is not `in_progress`.
  Future<String> addTreatment({
    required Role role,
    required String actorUserId,
    required String visitId,
    required String toothNumber,
    required String procedureName,
    required double unitPrice,
    required int quantity,
  });

  /// Edits a Performed Treatment belonging to an `in_progress` Visit.
  ///
  /// Throws [VisitNotEditableException] if the parent Visit is not
  /// `in_progress`.
  Future<void> updateTreatment({
    required Role role,
    required String treatmentId,
    required String toothNumber,
    required String procedureName,
    required double unitPrice,
    required int quantity,
  });

  /// Soft-deletes a Performed Treatment belonging to an `in_progress` Visit.
  ///
  /// Throws [VisitNotEditableException] if the parent Visit is not
  /// `in_progress`.
  Future<void> removeTreatment({
    required Role role,
    required String treatmentId,
  });
}
