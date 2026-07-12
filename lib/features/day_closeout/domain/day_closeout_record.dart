/// Domain-facing Day Closeout record, decoupled from Drift's generated row
/// class for the same reason as `PatientRecord` — see beads DocCentral-d0b.
class DayCloseoutRecord {
  const DayCloseoutRecord({
    required this.id,
    required this.closeoutDate,
    required this.expectedCash,
    required this.countedCash,
    required this.delta,
    required this.actorUserId,
    required this.recordedAt,
  });

  final String id;
  final DateTime closeoutDate;
  final double expectedCash;
  final double countedCash;
  final double delta;
  final String actorUserId;
  final DateTime recordedAt;
}
