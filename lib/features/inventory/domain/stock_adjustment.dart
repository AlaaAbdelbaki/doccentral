/// Domain-facing stock adjustment model, decoupled from Drift's generated
/// row class for the same reason as `PatientRecord` — see beads DocCentral-d0b.
class StockAdjustment {
  const StockAdjustment({
    required this.id,
    required this.inventoryItemId,
    required this.oldQuantity,
    required this.newQuantity,
    required this.delta,
    required this.reason,
    required this.actorUserId,
    required this.recordedAt,
  });

  final String id;
  final String inventoryItemId;
  final int oldQuantity;
  final int newQuantity;
  final int delta;
  final String reason;
  final String actorUserId;
  final DateTime recordedAt;
}
