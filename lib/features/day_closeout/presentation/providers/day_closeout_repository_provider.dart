import 'package:docentral/features/day_closeout/data/day_closeout_repository_impl.dart';
import 'package:docentral/features/day_closeout/domain/day_closeout_repository.dart';
import 'package:docentral/shared/data/providers/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'day_closeout_repository_provider.g.dart';

@riverpod
DayCloseoutRepository dayCloseoutRepository(Ref ref) {
  return DayCloseoutRepositoryImpl(ref.watch(appDatabaseProvider));
}
