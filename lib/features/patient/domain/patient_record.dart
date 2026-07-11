/// Domain-facing patient model, decoupled from Drift's generated `Patient`
/// row class — kept distinct because Drift's generated class breaks
/// riverpod_generator's type serialization in this project's current
/// dependency versions (see beads DocCentral-d0b).
class PatientRecord {
  const PatientRecord({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.phone,
    this.email,
    this.historyNotes,
  });

  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String phone;
  final String? email;
  final String? historyNotes;
}
