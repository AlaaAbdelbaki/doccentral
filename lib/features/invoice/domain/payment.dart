import 'package:docentral/features/invoice/domain/payment_method.dart';

/// Domain-facing payment model, decoupled from Drift's generated row class
/// for the same reason as `PatientRecord` — see beads DocCentral-d0b.
class Payment {
  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.method,
    required this.paymentDate,
    required this.recordedByUserId,
    this.notes,
  });

  final String id;
  final String invoiceId;
  final double amount;
  final PaymentMethod method;
  final DateTime paymentDate;
  final String recordedByUserId;
  final String? notes;
}
