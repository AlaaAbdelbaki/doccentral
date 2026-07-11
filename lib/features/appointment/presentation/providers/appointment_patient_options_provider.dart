import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:docentral/features/patient/presentation/providers/patient_repository_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'appointment_patient_options_provider.g.dart';

/// All active patients, unfiltered by the Patients page's own search
/// query — used to populate the patient picker in the appointment form.
@riverpod
Stream<List<PatientRecord>> appointmentPatientOptions(Ref ref) {
  final Role? role = ref.watch(currentRoleProvider);
  if (role == null) return Stream.value(const <PatientRecord>[]);

  return ref.watch(patientRepositoryProvider).watchAll(role: role);
}
