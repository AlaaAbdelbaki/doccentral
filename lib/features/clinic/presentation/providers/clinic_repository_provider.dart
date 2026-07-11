import 'package:docentral/features/clinic/data/clinic_repository_impl.dart';
import 'package:docentral/features/clinic/domain/clinic_repository.dart';
import 'package:docentral/shared/data/providers/app_database_provider.dart';
import 'package:docentral/shared/data/providers/auth_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clinic_repository_provider.g.dart';

@riverpod
ClinicRepository clinicRepository(Ref ref) {
  return ClinicRepositoryImpl(
    ref.watch(appDatabaseProvider),
    ref.watch(authServiceProvider),
  );
}
