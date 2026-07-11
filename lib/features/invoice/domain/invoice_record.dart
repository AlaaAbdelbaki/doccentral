import 'package:docentral/features/invoice/domain/invoice_status.dart';

/// Domain-facing invoice model, decoupled from Drift's generated `Invoice`
/// row class for the same reason as `PatientRecord` — see beads DocCentral-d0b.
class InvoiceRecord {
  const InvoiceRecord({
    required this.id,
    required this.patientId,
    required this.visitId,
    required this.totalAmount,
    required this.status,
    required this.createdByUserId,
  });

  final String id;
  final String patientId;
  final String visitId;
  final double totalAmount;
  final InvoiceStatus status;
  final String createdByUserId;
}
