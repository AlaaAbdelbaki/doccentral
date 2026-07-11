import 'package:docentral/features/visit/domain/visit_record.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

abstract class VisitRepository {
  /// Checks in a `scheduled` appointment: transitions it to `checked_in`
  /// and creates a linked Visit in `checked_in` status with
  /// `started_at = now()` (UTC). Returns the new Visit's id.
  ///
  /// Throws [AppointmentNotEditableException] if the appointment is not
  /// currently `scheduled`.
  Future<String> checkIn({required Role role, required String appointmentId});

  /// Streams the most recent [limit] visits for [patientId], newest first.
  Stream<List<VisitRecord>> watchRecentVisits({
    required Role role,
    required String patientId,
    int limit = 3,
  });
}
