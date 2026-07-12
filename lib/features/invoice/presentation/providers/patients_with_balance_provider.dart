import 'package:docentral/features/invoice/domain/patient_balance.dart';
import 'package:docentral/features/invoice/presentation/providers/invoice_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'patients_with_balance_provider.g.dart';

@riverpod
Stream<List<PatientBalance>> patientsWithBalance(Ref ref) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <PatientBalance>[]);

  return ref
      .watch(invoiceRepositoryProvider)
      .watchPatientsWithBalance(role: role);
}
