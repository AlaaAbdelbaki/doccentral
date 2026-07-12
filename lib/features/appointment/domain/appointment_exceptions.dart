class AppointmentValidationException implements Exception {
  const AppointmentValidationException(this.field);

  final String field;

  @override
  String toString() =>
      'AppointmentValidationException: missing required field "$field"';
}

/// Thrown when a new/edited appointment's time range overlaps an existing
/// appointment for the same assigned user. Callers should offer an explicit
/// override confirmation and retry with `overrideOverlap: true`.
class AppointmentOverlapException implements Exception {
  const AppointmentOverlapException();

  @override
  String toString() => 'AppointmentOverlapException';
}

/// Thrown when editing a non-`scheduled` appointment.
class AppointmentNotEditableException implements Exception {
  const AppointmentNotEditableException();

  static const String code = 'APPT_NOT_EDITABLE';

  @override
  String toString() => 'AppointmentNotEditableException: $code';
}

/// Thrown when linking a Planned Treatment that is already linked to a
/// different, non-cancelled appointment.
class PlannedTreatmentAlreadyBookedException implements Exception {
  const PlannedTreatmentAlreadyBookedException();

  @override
  String toString() => 'PlannedTreatmentAlreadyBookedException';
}
