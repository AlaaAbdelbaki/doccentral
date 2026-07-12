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
    this.reopenedAt,
  });

  final String id;
  final DateTime closeoutDate;
  final double expectedCash;
  final double countedCash;
  final double delta;
  final String actorUserId;
  final DateTime recordedAt;

  /// Non-null while the closeout is unlocked for re-entry via
  /// [DayCloseoutRepository.reopenCloseout]; cleared once re-confirmed.
  final DateTime? reopenedAt;

  bool get isReopened => reopenedAt != null;
}
