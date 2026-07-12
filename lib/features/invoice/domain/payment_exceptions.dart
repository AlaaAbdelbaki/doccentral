/// Thrown when a payment amount is not a positive number.
class PaymentValidationException implements Exception {
  const PaymentValidationException(this.message);

  final String message;

  @override
  String toString() => 'PaymentValidationException: $message';
}

/// Thrown when recording a Payment against a `voided` Invoice.
class PaymentInvoiceVoidedException implements Exception {
  const PaymentInvoiceVoidedException();

  @override
  String toString() => 'PaymentInvoiceVoidedException';
}
