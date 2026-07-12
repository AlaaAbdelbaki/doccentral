import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_patient_provider.g.dart';

// keepAlive: set from routes outside the shell's IndexedStack (e.g.
// PatientsWithBalancePage), whose full disposal on navigation would
// otherwise reset this selection before the destination page reads it.
@Riverpod(keepAlive: true)
class SelectedPatient extends _$SelectedPatient {
  @override
  PatientRecord? build() => null;

  void select(PatientRecord? patient) => state = patient;
}
