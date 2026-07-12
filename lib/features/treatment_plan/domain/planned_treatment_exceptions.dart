/// Thrown when marking a Planned Treatment as performed but it is not
/// currently `scheduled` (i.e. not linked to the appointment being
/// completed, or already done/cancelled).
class PlannedTreatmentNotScheduledException implements Exception {
  const PlannedTreatmentNotScheduledException();

  @override
  String toString() => 'PlannedTreatmentNotScheduledException';
}
