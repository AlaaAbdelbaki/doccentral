/// Domain-facing restock event model, decoupled from Drift's generated row
/// class for the same reason as `PatientRecord` — see beads DocCentral-d0b.
class RestockEvent {
  const RestockEvent({
    required this.id,
    required this.inventoryItemId,
    required this.quantityAdded,
    required this.restockDate,
    required this.actorUserId,
    required this.recordedAt,
    this.supplier,
    this.notes,
  });

  final String id;
  final String inventoryItemId;
  final int quantityAdded;
  final DateTime restockDate;
  final String actorUserId;
  final DateTime recordedAt;
  final String? supplier;
  final String? notes;
}
