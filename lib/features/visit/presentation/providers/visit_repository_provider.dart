import 'package:docentral/features/visit/data/visit_repository_impl.dart';
import 'package:docentral/features/visit/domain/visit_repository.dart';
import 'package:docentral/shared/data/providers/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'visit_repository_provider.g.dart';

@riverpod
VisitRepository visitRepository(Ref ref) {
  return VisitRepositoryImpl(ref.watch(appDatabaseProvider));
}
