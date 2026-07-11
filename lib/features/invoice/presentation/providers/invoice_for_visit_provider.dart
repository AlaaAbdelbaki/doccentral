import 'package:docentral/features/invoice/domain/invoice_record.dart';
import 'package:docentral/features/invoice/presentation/providers/invoice_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'invoice_for_visit_provider.g.dart';

@riverpod
Stream<InvoiceRecord?> invoiceForVisit(Ref ref, String visitId) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(null);

  return ref
      .watch(invoiceRepositoryProvider)
      .watchInvoiceForVisit(role: role, visitId: visitId);
}
