import 'package:docentral/features/treatment_plan/data/planned_treatment_repository_impl.dart';
import 'package:docentral/features/treatment_plan/domain/planned_treatment_repository.dart';
import 'package:docentral/shared/data/providers/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'planned_treatment_repository_provider.g.dart';

@riverpod
PlannedTreatmentRepository plannedTreatmentRepository(Ref ref) {
  return PlannedTreatmentRepositoryImpl(ref.watch(appDatabaseProvider));
}
