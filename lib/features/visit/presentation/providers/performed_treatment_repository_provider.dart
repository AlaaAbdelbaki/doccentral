import 'package:docentral/features/visit/data/performed_treatment_repository_impl.dart';
import 'package:docentral/features/visit/domain/performed_treatment_repository.dart';
import 'package:docentral/shared/data/providers/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'performed_treatment_repository_provider.g.dart';

@riverpod
PerformedTreatmentRepository performedTreatmentRepository(Ref ref) {
  return PerformedTreatmentRepositoryImpl(ref.watch(appDatabaseProvider));
}
