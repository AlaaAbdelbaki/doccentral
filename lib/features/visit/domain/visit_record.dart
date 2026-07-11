import 'package:docentral/features/visit/domain/visit_status.dart';

/// Domain-facing visit model, decoupled from Drift's generated `Visit` row
/// class for the same reason as `PatientRecord` — see beads DocCentral-d0b.
class VisitRecord {
  const VisitRecord({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.dentistId,
    required this.status,
    required this.startedAt,
    this.inProgressAt,
    this.diagnosis,
    this.clinicalNotes,
    this.endedAt,
  });

  final String id;
  final String appointmentId;
  final String patientId;
  final String dentistId;
  final VisitStatus status;
  final DateTime startedAt;
  final DateTime? inProgressAt;
  final String? diagnosis;
  final String? clinicalNotes;
  final DateTime? endedAt;
}
