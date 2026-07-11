import 'package:docentral/features/invoice/domain/invoice_adjustment_type.dart';
import 'package:docentral/features/invoice/domain/invoice_item.dart';
import 'package:docentral/features/invoice/domain/invoice_record.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

abstract class InvoiceRepository {
  /// Streams the Invoice linked to [visitId], or null if none exists yet.
  Stream<InvoiceRecord?> watchInvoiceForVisit({
    required Role role,
    required String visitId,
  });

  /// Streams the Invoice Items belonging to [invoiceId], oldest first —
  /// items mirroring Performed Treatments followed by any adjustments.
  Stream<List<InvoiceItem>> watchItemsForInvoice({
    required Role role,
    required String invoiceId,
  });

  /// Adds a discount or surcharge adjustment as an explicit Invoice Item,
  /// then recomputes the Invoice's `total_amount` as the sum of all of its
  /// Items (treatment mirrors and adjustments alike). The total is never a
  /// directly writable field — it is always derived from Items.
  ///
  /// Throws [InvoiceNotDraftException] if the Invoice is not `draft`.
  /// Throws [InvoiceAdjustmentValidationException] if [amount] is not a
  /// positive number.
  Future<String> addAdjustment({
    required Role role,
    required String invoiceId,
    required InvoiceAdjustmentType adjustmentType,
    required String description,
    required double amount,
  });

  /// Finalizes a `draft` Invoice with no payment: transitions it to
  /// `unpaid`, locking its Items and adjustments (enforced by
  /// [addAdjustment] rejecting any further changes), and logs [actorUserId]
  /// with a UTC timestamp.
  ///
  /// Throws [InvoiceNotDraftException] if the Invoice is not `draft`.
  Future<void> finalizeInvoice({
    required Role role,
    required String actorUserId,
    required String invoiceId,
  });
}
