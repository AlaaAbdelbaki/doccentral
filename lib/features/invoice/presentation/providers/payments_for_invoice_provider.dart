import 'package:docentral/features/invoice/domain/payment.dart';
import 'package:docentral/features/invoice/presentation/providers/payment_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payments_for_invoice_provider.g.dart';

@riverpod
Stream<List<Payment>> paymentsForInvoice(Ref ref, String invoiceId) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <Payment>[]);

  return ref
      .watch(paymentRepositoryProvider)
      .watchPaymentsForInvoice(role: role, invoiceId: invoiceId);
}
