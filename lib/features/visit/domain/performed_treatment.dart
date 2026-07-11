/// Domain-facing performed-treatment model, decoupled from Drift's generated
/// `PerformedTreatment` row class for the same reason as `PatientRecord` —
/// see beads DocCentral-d0b.
class PerformedTreatment {
  const PerformedTreatment({
    required this.id,
    required this.visitId,
    required this.toothNumber,
    required this.procedureName,
    required this.unitPrice,
    required this.quantity,
    required this.recordedByUserId,
    required this.recordedAt,
  });

  final String id;
  final String visitId;
  final String toothNumber;
  final String procedureName;
  final double unitPrice;
  final int quantity;
  final String recordedByUserId;
  final DateTime recordedAt;

  double get totalPrice => unitPrice * quantity;
}
