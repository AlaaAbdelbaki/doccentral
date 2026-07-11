import 'package:docentral/features/appointment/domain/appointment_record.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

abstract class AppointmentRepository {
  /// Streams today's (local device date) appointments in chronological
  /// (start time) order, excluding soft-deleted rows.
  Stream<List<AppointmentRecord>> watchToday({required Role role});
}
