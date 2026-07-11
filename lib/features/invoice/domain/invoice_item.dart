import 'package:docentral/features/invoice/domain/invoice_adjustment_type.dart';

/// Domain-facing invoice-item model, decoupled from Drift's generated
/// `InvoiceItem` row class for the same reason as `PatientRecord` — see
/// beads DocCentral-d0b.
///
/// [adjustmentType] is null for items mirroring a Performed Treatment, and
/// set to [InvoiceAdjustmentType.discount] or [InvoiceAdjustmentType.surcharge]
/// for adjustment items added in Story 7.1.
class InvoiceItem {
  const InvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.toothNumber,
    this.adjustmentType,
  });

  final String id;
  final String invoiceId;
  final String description;
  final String? toothNumber;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final InvoiceAdjustmentType? adjustmentType;
}
