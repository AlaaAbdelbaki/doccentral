import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

abstract class PatientRepository {
  Stream<List<PatientRecord>> watchAll({required Role role, String query = ''});

  Future<void> create({
    required Role role,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String phone,
    String? email,
    String? historyNotes,
  });

  /// Updates identity fields and history notes for an existing patient.
  /// Records an edit-log entry (actor, UTC timestamp, changed field names)
  /// when any field actually changes.
  Future<void> updatePatient({
    required Role role,
    required String actorUserId,
    required String patientId,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String phone,
    String? email,
    String? historyNotes,
  });

  /// Soft-deletes a patient: sets deleted_at so the patient disappears from
  /// search and lists. Existing Invoice/Payment records (Epic 7, not yet
  /// built) are unaffected — they key off patientId, not this deleted_at.
  Future<void> deletePatient({required Role role, required String patientId});
}
