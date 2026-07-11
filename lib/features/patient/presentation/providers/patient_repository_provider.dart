import 'package:docentral/features/patient/data/patient_repository_impl.dart';
import 'package:docentral/features/patient/domain/patient_repository.dart';
import 'package:docentral/shared/data/providers/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'patient_repository_provider.g.dart';

@riverpod
PatientRepository patientRepository(Ref ref) {
  return PatientRepositoryImpl(ref.watch(appDatabaseProvider));
}
