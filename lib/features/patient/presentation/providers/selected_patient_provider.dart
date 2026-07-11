import 'package:docentral/features/patient/domain/patient_record.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_patient_provider.g.dart';

@riverpod
class SelectedPatient extends _$SelectedPatient {
  @override
  PatientRecord? build() => null;

  void select(PatientRecord? patient) => state = patient;
}
