/// Thrown when an operation requires the Visit to be in a specific status
/// (e.g. `checked_in` to start progress, `in_progress` to record treatments)
/// and it currently isn't.
class VisitNotEditableException implements Exception {
  const VisitNotEditableException();

  static const String code = 'VISIT_NOT_EDITABLE';

  @override
  String toString() => 'VisitNotEditableException: $code';
}
