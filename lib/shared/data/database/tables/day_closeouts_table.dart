import 'package:docentral/shared/data/database/mixins/sync_metadata.dart';
import 'package:drift/drift.dart';

class DayCloseouts extends Table with SyncMetadata {
  DateTimeColumn get closeoutDate => dateTime()();
  RealColumn get expectedCash => real()();
  RealColumn get countedCash => real()();
  RealColumn get delta => real()();
  TextColumn get actorUserId => text()();
  DateTimeColumn get reopenedAt => dateTime().nullable()();
}
