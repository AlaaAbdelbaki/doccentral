class PatientValidationException implements Exception {
  const PatientValidationException(this.field);

  final String field;

  @override
  String toString() =>
      'PatientValidationException: missing required field "$field"';
}
