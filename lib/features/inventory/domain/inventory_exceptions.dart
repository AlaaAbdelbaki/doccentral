/// Thrown when creating an Inventory Item with a negative on-hand quantity
/// or a negative low-stock threshold.
class InventoryValidationException implements Exception {
  const InventoryValidationException(this.message);

  final String message;

  @override
  String toString() => 'InventoryValidationException: $message';
}
