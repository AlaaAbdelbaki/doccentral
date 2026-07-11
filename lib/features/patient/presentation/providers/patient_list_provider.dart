import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:docentral/features/patient/domain/patient_repository.dart';
import 'package:docentral/features/patient/presentation/providers/patient_repository_provider.dart';
import 'package:docentral/features/patient/presentation/providers/patient_search_query_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'patient_list_provider.g.dart';

@riverpod
Stream<List<PatientRecord>> patientList(Ref ref) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <PatientRecord>[]);

  final PatientRepository repository = ref.watch(patientRepositoryProvider);
  final String query = ref.watch(patientSearchQueryProvider);
  return repository.watchAll(role: role, query: query);
}
