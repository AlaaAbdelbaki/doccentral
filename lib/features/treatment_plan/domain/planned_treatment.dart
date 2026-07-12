import 'package:docentral/features/treatment_plan/domain/planned_treatment_status.dart';

/// Domain-facing planned-treatment model, decoupled from Drift's generated
/// row class for the same reason as `PatientRecord` — see beads
/// DocCentral-d0b.
class PlannedTreatment {
  const PlannedTreatment({
    required this.id,
    required this.patientId,
    required this.procedureName,
    required this.toothNumber,
    required this.estimatedUnitPrice,
    required this.sequenceNumber,
    required this.status,
    this.targetDate,
  });

  final String id;
  final String patientId;
  final String procedureName;
  final String toothNumber;
  final double estimatedUnitPrice;
  final int sequenceNumber;
  final PlannedTreatmentStatus status;

  /// Null means "next available" — no fixed target date.
  final DateTime? targetDate;
}
