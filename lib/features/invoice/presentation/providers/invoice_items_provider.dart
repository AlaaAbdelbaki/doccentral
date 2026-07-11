import 'package:docentral/features/invoice/domain/invoice_item.dart';
import 'package:docentral/features/invoice/presentation/providers/invoice_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'invoice_items_provider.g.dart';

@riverpod
Stream<List<InvoiceItem>> invoiceItems(Ref ref, String invoiceId) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <InvoiceItem>[]);

  return ref
      .watch(invoiceRepositoryProvider)
      .watchItemsForInvoice(role: role, invoiceId: invoiceId);
}
