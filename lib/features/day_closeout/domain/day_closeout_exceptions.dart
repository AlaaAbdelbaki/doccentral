/// Thrown when confirming a Day Closeout for a date that already has one —
/// one closeout per clinic per date is enforced.
class DayCloseoutAlreadyExistsException implements Exception {
  const DayCloseoutAlreadyExistsException();

  @override
  String toString() => 'DayCloseoutAlreadyExistsException';
}
