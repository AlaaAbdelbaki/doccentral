import 'package:docentral/features/appointment/data/appointment_repository_impl.dart';
import 'package:docentral/features/appointment/domain/appointment_repository.dart';
import 'package:docentral/shared/data/providers/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appointment_repository_provider.g.dart';

@riverpod
AppointmentRepository appointmentRepository(Ref ref) {
  return AppointmentRepositoryImpl(ref.watch(appDatabaseProvider));
}
