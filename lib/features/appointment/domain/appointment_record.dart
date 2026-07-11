import 'package:docentral/features/appointment/domain/appointment_status.dart';

/// Domain-facing appointment model, decoupled from Drift's generated
/// `Appointment` row class for the same reason as `PatientRecord` — see
/// beads DocCentral-d0b. Denormalizes the patient's display name since the
/// calendar row needs it directly without a second lookup.
class AppointmentRecord {
  const AppointmentRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.assignedUserId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.reason,
    this.notes,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String assignedUserId;
  final DateTime startTime;
  final DateTime endTime;
  final AppointmentStatus status;
  final String? reason;
  final String? notes;
}
