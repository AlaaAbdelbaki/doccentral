import 'package:docentral/features/treatment_plan/domain/planned_treatment.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

abstract class PlannedTreatmentRepository {
  /// Streams the Planned Treatments for [patientId] in sequence order.
  Stream<List<PlannedTreatment>> watchForPatient({
    required Role role,
    required String patientId,
  });

  /// Adds a Planned Treatment to [patientId]'s treatment plan with status
  /// `planned`. The sequence number is auto-assigned as one past the
  /// patient's current highest sequence number. Doctor-only.
  ///
  /// [targetDate] is optional — null means "next available", no fixed date.
  Future<String> addPlannedTreatment({
    required Role role,
    required String patientId,
    required String procedureName,
    required String toothNumber,
    required double estimatedUnitPrice,
    DateTime? targetDate,
  });
}
