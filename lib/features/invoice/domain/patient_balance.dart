import 'package:docentral/features/patient/domain/patient_record.dart';

/// A patient with a current Outstanding Balance greater than zero.
class PatientBalance {
  const PatientBalance({
    required this.patient,
    required this.balance,
    this.lastPaymentDate,
  });

  final PatientRecord patient;
  final double balance;

  /// The date of this patient's most recent Payment across all of their
  /// non-`voided` Invoices, or null if they have never made one.
  final DateTime? lastPaymentDate;
}
