/// Thrown when an operation requires the Visit to be in a specific status
/// (e.g. `checked_in` to start progress, `in_progress` to record treatments)
/// and it currently isn't.
class VisitNotEditableException implements Exception {
  const VisitNotEditableException();

  static const String code = 'VISIT_NOT_EDITABLE';

  @override
  String toString() => 'VisitNotEditableException: $code';
}

/// Thrown when completing a Visit with no recorded Performed Treatments.
class VisitRequiresTreatmentException implements Exception {
  const VisitRequiresTreatmentException();

  @override
  String toString() => 'VisitRequiresTreatmentException';
}

/// Thrown when unlocking a Visit whose linked Invoice has recorded Payments
/// (status `partially_paid` or `paid`) — it must be voided first.
class VisitInvoiceHasPaymentsException implements Exception {
  const VisitInvoiceHasPaymentsException();

  @override
  String toString() => 'VisitInvoiceHasPaymentsException';
}

/// Thrown when unlocking a Visit whose linked Invoice has been `voided`.
/// A finalized-but-unpaid Invoice (`unpaid`) is unlocked back to `draft`
/// along with the Visit — see [VisitRepository.unlockVisit] — this
/// exception is reserved for the `voided` dead end.
class VisitInvoiceFinalizedException implements Exception {
  const VisitInvoiceFinalizedException();

  @override
  String toString() => 'VisitInvoiceFinalizedException';
}
