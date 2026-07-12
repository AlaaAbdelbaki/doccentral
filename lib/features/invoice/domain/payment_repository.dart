import 'package:docentral/features/invoice/domain/payment.dart';
import 'package:docentral/features/invoice/domain/payment_method.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

abstract class PaymentRepository {
  /// Streams the Payments recorded against [invoiceId], oldest first.
  Stream<List<Payment>> watchPaymentsForInvoice({
    required Role role,
    required String invoiceId,
  });

  /// Records an immutable Payment against a non-`voided` Invoice.
  ///
  /// If the Invoice is still `draft`, it is auto-finalized (`draft` ->
  /// `unpaid`, logged as in [InvoiceRepository.finalizeInvoice]) before the
  /// Payment is recorded. The Invoice's status is then re-derived — never
  /// directly writable — from the sum of all its Payments compared to its
  /// total: `partially_paid` while the sum is less than the total, `paid`
  /// once it reaches or exceeds it. [paymentDate] defaults to today (UTC)
  /// when omitted. Returns the new Payment's id.
  ///
  /// Throws [PaymentInvoiceVoidedException] if the Invoice is `voided`.
  /// Throws [PaymentValidationException] if [amount] is not positive.
  Future<String> recordPayment({
    required Role role,
    required String actorUserId,
    required String invoiceId,
    required double amount,
    PaymentMethod method = PaymentMethod.cash,
    DateTime? paymentDate,
    String? notes,
  });
}
