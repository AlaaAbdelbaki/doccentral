import 'package:docentral/features/invoice/presentation/providers/invoice_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'outstanding_balance_provider.g.dart';

@riverpod
Stream<double> outstandingBalance(Ref ref, String patientId) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(0);

  return ref
      .watch(invoiceRepositoryProvider)
      .watchOutstandingBalanceForPatient(role: role, patientId: patientId);
}
