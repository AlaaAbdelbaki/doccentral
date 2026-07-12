/// Thrown when adding an adjustment to, or finalizing, an Invoice that is
/// no longer `draft`.
class InvoiceNotDraftException implements Exception {
  const InvoiceNotDraftException();

  @override
  String toString() => 'InvoiceNotDraftException';
}

/// Thrown when an adjustment amount is not a positive number.
class InvoiceAdjustmentValidationException implements Exception {
  const InvoiceAdjustmentValidationException(this.message);

  final String message;

  @override
  String toString() => 'InvoiceAdjustmentValidationException: $message';
}

/// Thrown when voiding an Invoice that has already been voided.
class InvoiceAlreadyVoidedException implements Exception {
  const InvoiceAlreadyVoidedException();

  @override
  String toString() => 'InvoiceAlreadyVoidedException';
}
